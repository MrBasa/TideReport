## TideReport :: GitHub Prompt Item
##
## This is the main function that Tide calls to display GitHub data. 

if not functions -q __tide_report_lock_acquire
    source (status filename | path dirname)/_tide_report_lock_helpers.fish
end

function __tide_report_github_path_within --description "Return success when path is inside repo_root" --argument-names candidate repo_root
    test -n "$candidate"; and test -n "$repo_root"; or return 1
    if test "$candidate" = "$repo_root"
        return 0
    end
    string match -q -- "$repo_root/*" "$candidate"
end

function __tide_report_github_file_mtime --description "Return file mtime using Fish builtins" --argument-names file_path
    set -l stamp (path mtime -- "$file_path" 2>/dev/null | string collect | string trim)
    string match -qr '^[0-9]+$' -- "$stamp"; or return 1
    echo "$stamp"
end

function __tide_report_github_stats_file --description "Return stats sidecar file for repo cache" --argument-names cache_file
    echo "$cache_file.stats"
end

function __tide_report_github_state_file --description "Return CI sidecar file for CI cache" --argument-names ci_cache_file
    echo "$ci_cache_file.state"
end

function __tide_report_github_stats_line_valid --description "Validate compact GitHub stats line" --argument-names line
    set -l parts (string split " " -- (string trim -- "$line"))
    test (count $parts) -eq 5; or return 1

    for value in $parts
        string match -qr '^[0-9]+$' -- "$value"; or return 1
    end

    return 0
end

function __tide_report_github_ci_state_valid --description "Validate normalized GitHub CI state" --argument-names ci_state
    contains -- "$ci_state" pass fail pending none
end

function __tide_report_github_ci_cache_file --description "Return CI cache path for cache key and branch" --argument-names cache_dir cache_key branch
    set -l branch_safe detached
    if test -n "$branch"
        set branch_safe (string replace -a -r '[^a-zA-Z0-9._-]' '_' "$branch")
    end
    echo "$cache_dir/$cache_key-$branch_safe-ci.json"
end

function __tide_report_github_branch_from_head --description "Read branch name from git HEAD without invoking git" --argument-names git_dir
    set -l head_file "$git_dir/HEAD"
    test -f "$head_file"; or return 1

    set -l head_ref ""
    read -l head_ref < "$head_file"
    if string match -qr '^ref: refs/heads/' -- "$head_ref"
        string replace -r '^ref: refs/heads/' '' -- "$head_ref"
    end
end

function __tide_report_github_stats_from_json --description "Extract compact stats line from repo JSON" --argument-names cache_file
    command jq -r '[.stargazerCount,.forkCount,.watchers.totalCount,.issues.totalCount,.pullRequests.totalCount]|join(" ")' "$cache_file" 2>/dev/null
end

function __tide_report_github_read_stats_line --description "Read GitHub stats from sidecar or legacy JSON fallback" --argument-names cache_file
    set -l stats_file (__tide_report_github_stats_file "$cache_file")
    if test -f "$stats_file"
        set -l line ""
        read -l line < "$stats_file"
        if __tide_report_github_stats_line_valid "$line"
            echo "$line"
            return 0
        end
    end

    set -l line (__tide_report_github_stats_from_json "$cache_file")
    if __tide_report_github_stats_line_valid "$line"
        echo "$line"
        return 0
    end

    return 1
end

function __tide_report_github_ci_state_from_json --description "Normalize GitHub CI state from legacy JSON cache" --argument-names ci_cache_file
    set -l first (command jq -r 'if length > 0 then (.[0] | "\(.status) \(.conclusion)") else "" end' "$ci_cache_file" 2>/dev/null)
    if test -z "$first"; or test "$first" = "null null"
        echo none
        return 0
    end

    set -l parts (string split " " "$first")
    set -l run_status "$parts[1]"
    set -l conclusion "$parts[2]"
    if test "$run_status" = "completed"
        if test "$conclusion" = "success"
            echo pass
        else
            echo fail
        end
    else
        echo pending
    end
end

function __tide_report_github_read_ci_state --description "Read normalized GitHub CI state from sidecar or legacy JSON fallback" --argument-names ci_cache_file
    set -l state_file (__tide_report_github_state_file "$ci_cache_file")
    if test -f "$state_file"
        set -l ci_state ""
        read -l ci_state < "$state_file"
        if __tide_report_github_ci_state_valid "$ci_state"
            echo "$ci_state"
            return 0
        end
    end

    test -f "$ci_cache_file"; or return 1
    set -l ci_state (__tide_report_github_ci_state_from_json "$ci_cache_file")
    if __tide_report_github_ci_state_valid "$ci_state"
        echo "$ci_state"
        return 0
    end

    return 1
end

function _tide_item_github --description "Displays GitHub stats"
    set -l now (command date +%s)
    set -l context (__tide_report_github_context)
    test (count $context) -ge 6; or return 0

    set -l api_slug $context[1]
    set -l cache_key $context[2]
    set -l cache_dir $context[3]
    set -l cache_file $context[4]
    set -l git_dir $context[6]
    set -l branch (__tide_report_github_branch_from_head "$git_dir" | string collect)
    set -l ci_cache_file (__tide_report_github_ci_cache_file "$cache_dir" "$cache_key" "$branch")
    set -l refresh_seconds $tide_report_github_refresh_seconds
    set -l ci_refresh_seconds $tide_report_github_ci_refresh_seconds
    set -l timeout_sec (math --scale=0 "$tide_report_service_timeout_millis / 1000")

    ## --- Async Logic ---
    set -l trigger_fetch false
    set -l trigger_ci_fetch false
    set -l output_valid false

    # Check cache status
    if test -f "$cache_file"
        set -l mod_time (__tide_report_github_file_mtime "$cache_file" | string collect)
        test -n "$mod_time"; or set mod_time 0
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
            set -l ci_mod (__tide_report_github_file_mtime "$ci_cache_file" | string collect)
            test -n "$ci_mod"; or set ci_mod 0
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
        set -l lock_var "github_$clean_key"
        if __tide_report_lock_acquire "$lock_var" "$now" 120
            mkdir -p "$cache_dir"
            __tide_report_fetch_github "$api_slug" "$cache_file" "$timeout_sec" "$lock_var" &
            disown 2>/dev/null  # Avoid prompt delay; ignore "no suitable jobs" if job already finished
        end
    end

    # Trigger CI fetch if needed (skip when branch is empty, e.g. detached HEAD)
    if test "$trigger_ci_fetch" = true; and test -n "$branch"
        set -l branch_safe (string replace -a -r '[^a-zA-Z0-9_]' '_' "$branch")
        set -l ci_lock_var "github_ci_"$clean_key"_"$branch_safe
        if __tide_report_lock_acquire "$ci_lock_var" "$now" 120
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

function __tide_report_github_context --description "Resolve repo/cache metadata and cache it per repo root"
    if set -q __tide_report_github_context_repo_root
        if __tide_report_github_path_within "$PWD" "$__tide_report_github_context_repo_root"
            printf "%s\n" $__tide_report_github_context_values
            return 0
        end
    end

    set -l repo_root (command git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$repo_root"
        return 1
    end
    set repo_root (path normalize "$repo_root")

    set -l git_dir (command git rev-parse --git-dir 2>/dev/null)
    if test -z "$git_dir"
        return 1
    end
    if not string match -q '/*' -- "$git_dir"
        set git_dir (path normalize "$PWD/$git_dir")
    end

    set -l remote_url (command git config --get remote.origin.url 2>/dev/null)
    if test -z "$remote_url"
        return 1
    end
    if not string match -qr 'github\.com[/:]' "$remote_url"
        return 1
    end

    set -l repo_parts (string replace -r '^.*[:/]([^/]+)/([^/]+?)(\.git)?$' '$1\n$2' -- "$remote_url")
    set -l owner (string trim -- $repo_parts[1])
    set -l repo (string trim -- $repo_parts[2])
    if test -z "$owner"; or test -z "$repo"
        return 1
    end

    set -l api_slug "$owner/$repo"
    set -l cache_key "$owner-$repo"
    set -l cache_dir "$HOME/.cache/tide-report/github"
    set -l cache_file "$cache_dir/$cache_key.json"

    set -g __tide_report_github_context_repo_root "$repo_root"
    set -g __tide_report_github_context_values "$api_slug" "$cache_key" "$cache_dir" "$cache_file" "$repo_root" "$git_dir"
    printf "%s\n" $__tide_report_github_context_values
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
        set line (__tide_report_github_read_stats_line "$cache_file" | string collect)
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
    if test "$tide_report_github_show_ci" = true; and test -n "$ci_cache_file"
        set -l parsed_ci_state (__tide_report_github_read_ci_state "$ci_cache_file" | string collect)
        test -n "$parsed_ci_state"; and set ci_state "$parsed_ci_state"
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
        __tide_report_lock_release "$lock_var"
    end

    set -l temp_file "$cache_file.$fish_pid.tmp"
    set -l stats_file (__tide_report_github_stats_file "$cache_file")
    set -l stats_temp "$stats_file.$fish_pid.tmp"

    # Fetch data and store in temp file
    set -l json_data (gh repo view "$api_slug" --json 'nameWithOwner,stargazerCount,forkCount,issues,pullRequests,watchers' 2>/dev/null)
    set -l stats_line ""
    if test $status -eq 0; and test -n "$json_data"
        set stats_line (printf "%s" "$json_data" | command jq -r '[.stargazerCount,.forkCount,.watchers.totalCount,.issues.totalCount,.pullRequests.totalCount]|join(" ")' 2>/dev/null)
    end

    # Check if fetch was successful
    if test $status -eq 0; and test -n "$json_data"; and __tide_report_github_stats_line_valid "$stats_line"
        printf "%s\n" "$json_data" >"$temp_file"
        printf "%s\n" "$stats_line" >"$stats_temp"
        command mv -f "$temp_file" "$cache_file"
        command mv -f "$stats_temp" "$stats_file"
    else
        command rm -f "$temp_file" "$stats_temp" 2>/dev/null
        functions -q __tide_report_log_expected && __tide_report_log_expected github "fetch failed (check gh auth and network)"
    end
end

## --- Fetch GitHub CI status (Background Worker) ---
function __tide_report_fetch_github_ci --description "Fetch latest workflow run for branch and write CI cache JSON" --argument-names api_slug branch ci_cache_file lock_var
    function _remove_ci_lock --description "Clear GitHub CI fetch lock when background worker exits" --on-process-exit $fish_pid --on-signal INT --on-signal TERM --inherit-variable lock_var
        __tide_report_lock_release "$lock_var"
    end

    set -l temp_file "$ci_cache_file.$fish_pid.tmp"
    set -l state_file (__tide_report_github_state_file "$ci_cache_file")
    set -l state_temp "$state_file.$fish_pid.tmp"
    set -l json_data (gh run list -R "$api_slug" -b "$branch" -L 1 --json status,conclusion,name 2>/dev/null)
    set -l ci_state ""
    if test $status -eq 0; and test -n "$json_data"
        set ci_state (printf "%s" "$json_data" | command jq -r 'if length == 0 then "none" else (.[0] | if .status == "completed" then (if .conclusion == "success" then "pass" else "fail" end) else "pending" end) end' 2>/dev/null)
    end

    if test $status -eq 0; and test -n "$json_data"; and __tide_report_github_ci_state_valid "$ci_state"
        printf "%s\n" "$json_data" >"$temp_file"
        printf "%s\n" "$ci_state" >"$state_temp"
        command mv -f "$temp_file" "$ci_cache_file"
        command mv -f "$state_temp" "$state_file"
    else
        command rm -f "$temp_file" "$state_temp" 2>/dev/null
    end
end
