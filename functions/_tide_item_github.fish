## TideReport :: GitHub Prompt Item
##
## This is the main function that Tide calls to display GitHub data. 

function _tide_item_github --description "Displays GitHub stats"
    ## --- Quick Checks ---
    # Verify we are in a git repo (suppress git's fatal message when not in a repo)
    if not command git rev-parse --is-inside-work-tree 2>/dev/null >/dev/null
        return 0 # Not git dir
    end

    # Get the remote URL to determine the Repo Identity
    set -l remote_url (command git config --get remote.origin.url 2>/dev/null)
    if test -z "$remote_url"
        return 0 # No remote 'origin' found
    end

    # Parse Owner and Repo Name
    # Handles: https://github.com/Owner/Repo.git and git@github.com:Owner/Repo.git
    set -l repo_parts (echo "$remote_url" | string replace -r '^.*[:/]([^/]+)/([^/]+?)(\.git)?$' '$1\n$2')
    set -l owner (string trim -- $repo_parts[1])
    set -l repo (string trim -- $repo_parts[2])

    if test -z "$owner"; or test -z "$repo"
        return 0 # Could not parse owner/repo
    end

    set -l api_slug "$owner/$repo" # Format for gh command: "Owner/Repo"
    set -l cache_key "$owner-$repo" # Format for filename: "Owner-Repo"

    set -l cache_dir "$HOME/.cache/tide-report/github"
    set -l cache_file "$cache_dir/$cache_key.json"
    set -l refresh_seconds $tide_report_github_refresh_seconds
    set -l ci_refresh_seconds $tide_report_github_ci_refresh_seconds
    set -l timeout_sec (math --scale=0 "$tide_report_service_timeout_millis / 1000")

    set -l branch (command git branch --show-current 2>/dev/null; or echo "")
    set -l branch_safe (string replace -a -r '[^a-zA-Z0-9._-]' '_' "$branch")
    test -z "$branch_safe" && set branch_safe "detached"
    set -l ci_cache_file "$cache_dir/$cache_key-$branch_safe-ci.json"

    ## --- Async Logic ---
    set -l trigger_fetch false
    set -l trigger_ci_fetch false
    set -l output_valid false
    set -l now (command date +%s)

    # Check cache status
    if test -f "$cache_file"
        set -l mod_time (command date -r "$cache_file" +%s 2>/dev/null; or echo 0)
        set -l age (math $now - $mod_time)

        # Check if cache is stale
        if test $age -gt $refresh_seconds
            set trigger_fetch true
        end
        set output_valid true
    else
        # No cache exists
        set trigger_fetch true
    end

    # Check CI cache when show_ci is enabled
    if test "$tide_report_github_show_ci" = true
        if test -f "$ci_cache_file"
            set -l ci_mod (command date -r "$ci_cache_file" +%s 2>/dev/null; or echo 0)
            if test (math $now - $ci_mod) -gt $ci_refresh_seconds
                set trigger_ci_fetch true
            end
        else
            set trigger_ci_fetch true
        end
    end

    # Trigger background fetch if needed
    set -l clean_key (string replace -a -r '[^a-zA-Z0-9_]' '_' "$cache_key")
    if test "$trigger_fetch" = true
        set -l lock_var "_tide_report_gh_lock_$clean_key"

        set -l lock_time 0
        if set -q $lock_var
            set lock_time $$lock_var
        end

        # Only fetch if lock is old (> 120s) or non-existent
        if test (math $now - $lock_time) -gt 120
            set -U $lock_var $now
            mkdir -p "$cache_dir"
            __tide_report_fetch_github "$api_slug" "$cache_file" "$timeout_sec" "$lock_var" &
            disown 2>/dev/null  # Avoid prompt delay; ignore "no suitable jobs" if job already finished
        end
    end

    # Trigger CI fetch if needed (skip when branch is empty, e.g. detached HEAD)
    if test "$trigger_ci_fetch" = true; and test -n "$branch"
        set -l ci_lock_var "_tide_report_gh_ci_lock_"$clean_key"_"(string replace -a -r '[^a-zA-Z0-9_]' '_' "$branch_safe")
        set -l ci_lock_time 0
        if set -q $ci_lock_var
            set ci_lock_time $$ci_lock_var
        end
        if test (math $now - $ci_lock_time) -gt 120
            set -U $ci_lock_var $now
            mkdir -p "$cache_dir"
            __tide_report_fetch_github_ci "$api_slug" "$branch" "$ci_cache_file" "$ci_lock_var" &
            disown 2>/dev/null
        end
    end

    if test "$output_valid" = true
        # Cache is valid (or stale but usable), parse and print
        if test "$tide_report_github_show_ci" = true
            __tide_report_parse_github "$cache_file" "" "$ci_cache_file"
        else
            __tide_report_parse_github "$cache_file"
        end
    else
        # Data is missing, display loading message
        _tide_print_item github (set_color $tide_report_github_unavailable_color)$tide_report_github_unavailable_text
    end
end

## --- Render: display inputs → formatted string (no I/O) ---
function __tide_report_render_github --description "Render GitHub segment from stars/forks/watchers/issues/prs and ci_state (pass|fail|pending|none)" --argument-names stars forks watchers issues prs ci_state
    set -q stars || set stars 0
    set -q forks || set forks 0
    set -q watchers || set watchers 0
    set -q issues || set issues 0
    set -q prs || set prs 0
    set -q ci_state || set ci_state none

    # Ensure we have display values (avoid empty output when run from tests or minimal env)
    set -q tide_report_github_icon; or set -l tide_report_github_icon ""
    set -q tide_report_github_icon_stars; or set -l tide_report_github_icon_stars "★"
    set -q tide_report_github_icon_forks; or set -l tide_report_github_icon_forks "⑂"
    set -q tide_report_github_icon_watchers; or set -l tide_report_github_icon_watchers ""
    set -q tide_report_github_icon_issues; or set -l tide_report_github_icon_issues "!"
    set -q tide_report_github_icon_prs; or set -l tide_report_github_icon_prs "PR"
    set -q tide_report_github_color_stars; or set -l tide_report_github_color_stars "yellow"
    set -q tide_report_github_color_forks; or set -l tide_report_github_color_forks "yellow"
    set -q tide_report_github_color_watchers; or set -l tide_report_github_color_watchers "yellow"
    set -q tide_report_github_color_issues; or set -l tide_report_github_color_issues "yellow"
    set -q tide_report_github_color_prs; or set -l tide_report_github_color_prs "yellow"

    set -l icon "$tide_report_github_icon"
    test -z "$icon"; and set icon ""
    set -l output "$icon"
    # TIDE_REPORT_TEST: skip set_color so tests can assert on output (Fish may drop args with escape codes)
    if not set -q TIDE_REPORT_TEST
        test "$stars" != 0 && set output "$output"(set_color $tide_report_github_color_stars)" $tide_report_github_icon_stars$stars"
        test "$forks" != 0 && set output "$output"(set_color $tide_report_github_color_forks)" $tide_report_github_icon_forks$forks"
        test "$watchers" != 0 && set output "$output"(set_color $tide_report_github_color_watchers)" $tide_report_github_icon_watchers$watchers"
        test "$issues" != 0 && set output "$output"(set_color $tide_report_github_color_issues)" $tide_report_github_icon_issues$issues"
        test "$prs" != 0 && set output "$output"(set_color $tide_report_github_color_prs)" $tide_report_github_icon_prs$prs"
    else
        test "$stars" != 0 && set output "$output $tide_report_github_icon_stars$stars"
        test "$forks" != 0 && set output "$output $tide_report_github_icon_forks$forks"
        test "$watchers" != 0 && set output "$output $tide_report_github_icon_watchers$watchers"
        test "$issues" != 0 && set output "$output $tide_report_github_icon_issues$issues"
        test "$prs" != 0 && set output "$output $tide_report_github_icon_prs$prs"
    end

    # Append CI status when show_ci is enabled and ci_state is set (pass|fail|pending)
    if test "$tide_report_github_show_ci" = true; and test -n "$ci_state"; and test "$ci_state" != "none"
        set -q tide_report_github_icon_ci_pass; or set -l tide_report_github_icon_ci_pass "✔"
        set -q tide_report_github_icon_ci_fail; or set -l tide_report_github_icon_ci_fail "✗"
        set -q tide_report_github_icon_ci_pending; or set -l tide_report_github_icon_ci_pending "⋯"
        set -q tide_report_github_color_ci_pass; or set -l tide_report_github_color_ci_pass "green"
        set -q tide_report_github_color_ci_fail; or set -l tide_report_github_color_ci_fail "red"
        set -q tide_report_github_color_ci_pending; or set -l tide_report_github_color_ci_pending "yellow"
        if not set -q TIDE_REPORT_TEST
            switch "$ci_state"
                case pass
                    set output "$output "(set_color $tide_report_github_color_ci_pass)$tide_report_github_icon_ci_pass
                case fail
                    set output "$output "(set_color $tide_report_github_color_ci_fail)$tide_report_github_icon_ci_fail
                case "*"
                    set output "$output "(set_color $tide_report_github_color_ci_pending)$tide_report_github_icon_ci_pending
            end
        else
            switch "$ci_state"
                case pass
                    set output "$output $tide_report_github_icon_ci_pass"
                case fail
                    set output "$output $tide_report_github_icon_ci_fail"
                case "*"
                    set output "$output $tide_report_github_icon_ci_pending"
            end
        end
    end

    if test -n "$output"
        string trim "$output"
    end
end

## --- Parser Function ---
function __tide_report_parse_github --description "Parse cached GitHub repo stats JSON and print a formatted segment"
    set -l cache_file $argv[1]
    set -l line ""
    if set -q argv[2]; and test -n "$argv[2]"
        set line $argv[2]
    else
        set line (command jq -r '[.stargazerCount,.forkCount,.watchers.totalCount,.issues.totalCount,.pullRequests.totalCount]|join(" ")' "$cache_file" 2>/dev/null)
    end
    set -l ci_cache_file ""
    set -q argv[3]; and test -n "$argv[3]"; and set ci_cache_file "$argv[3]"
    set -l stars ""
    set -l forks ""
    set -l watchers ""
    set -l issues ""
    set -l prs ""
    if test -n "$line"
        set -l parts (string split " " "$line")
        set stars $parts[1]
        set forks $parts[2]
        set watchers $parts[3]
        set issues $parts[4]
        set prs $parts[5]
    end

    if test -z "$stars"
        _tide_print_item github (set_color $tide_report_github_unavailable_color)$tide_report_github_unavailable_text
        return
    end

    # Extract CI state from cache when show_ci is enabled
    set -l ci_state "none"
    if test "$tide_report_github_show_ci" = true; and test -n "$ci_cache_file"; and test -f "$ci_cache_file"
        # Empty array (no workflows) yields no output; do not show any CI icon
        set -l first (command jq -r 'if length > 0 then (.[0] | "\(.status) \(.conclusion)") else "" end' "$ci_cache_file" 2>/dev/null)
        if test -n "$first"; and test "$first" != "null null"
            set -l parts (string split " " "$first")
            set -l run_status "$parts[1]"
            set -l conclusion "$parts[2]"
            if test "$run_status" = "completed"
                if test "$conclusion" = "success"
                    set ci_state "pass"
                else
                    set ci_state "fail"
                end
            else
                set ci_state "pending"
            end
        end
    end

    set -l out (__tide_report_render_github "$stars" "$forks" "$watchers" "$issues" "$prs" "$ci_state")
    if test -n "$out"
        _tide_print_item github "$out"
    end
end

## --- Fetch GitHub Data (Background Worker) ---
function __tide_report_fetch_github --description "Fetch GitHub repo stats with gh and write cache JSON" --argument-names api_slug cache_file timeout_sec lock_var
    # Auto-cleanup lock
    function _remove_lock --description "Clear GitHub fetch lock when background worker exits" --on-process-exit $fish_pid --on-signal INT --on-signal TERM --inherit-variable lock_var
        set -U -e $lock_var
    end

    set -l temp_file "$cache_file.$fish_pid.tmp"

    # Fetch data and store in temp file
    set -l json_data (gh repo view "$api_slug" --json 'nameWithOwner,stargazerCount,forkCount,issues,pullRequests,watchers' 2>/dev/null)

    # Check if fetch was successful
    if test $status -eq 0; and test -n "$json_data"
        echo "$json_data" >"$temp_file"
        command mv -f "$temp_file" "$cache_file"
    else
        functions -q __tide_report_log_expected && __tide_report_log_expected github "fetch failed (check gh auth and network)"
    end
end

## --- Fetch GitHub CI status (Background Worker) ---
function __tide_report_fetch_github_ci --description "Fetch latest workflow run for branch and write CI cache JSON" --argument-names api_slug branch ci_cache_file lock_var
    function _remove_ci_lock --description "Clear GitHub CI fetch lock when background worker exits" --on-process-exit $fish_pid --on-signal INT --on-signal TERM --inherit-variable lock_var
        set -U -e $lock_var
    end

    set -l temp_file "$ci_cache_file.$fish_pid.tmp"
    set -l json_data (gh run list -R "$api_slug" -b "$branch" -L 1 --json status,conclusion,name 2>/dev/null)

    if test $status -eq 0; and test -n "$json_data"
        echo "$json_data" >"$temp_file"
        command mv -f "$temp_file" "$ci_cache_file"
    end
end
