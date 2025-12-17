# TideReport :: GitHub Prompt Item
#
# This is the main function that Tide calls to display GitHub data. 

function _tide_item_github --description "Displays GitHub stats"
    # --- Quick Checks ---
    # Verify we are in a git repo
    if not git rev-parse --is-inside-work-tree &>/dev/null
        return 0 # Not git dir
    end

    # Get the remote URL to determine the Repo Identity
    set -l remote_url (git config --get remote.origin.url 2>/dev/null)
    if test -z "$remote_url"
        return 0 # No remote 'origin' found
    end

    # Parse Owner and Repo Name
    # Handles: https://github.com/Owner/Repo.git and git@github.com:Owner/Repo.git
    set -l repo_parts (echo "$remote_url" | string replace -r '^.*[:/]([^/]+)/([^/]+?)(\.git)?$' '$1\n$2')
    set -l owner (string trim -- $repo_parts[1])
    set -l repo (string trim -- $repo_parts[2])

    if test -z "$owner" -o -z "$repo"
        return 0 # Could not parse owner/repo
    end

    set -l api_slug "$owner/$repo" # Format for gh command: "Owner/Repo"
    set -l cache_key "$owner-$repo" # Format for filename: "Owner-Repo"

    set -l cache_dir "$HOME/.cache/tide-report/github"
    set -l cache_file "$cache_dir/$cache_key.json"
    set -l refresh_seconds $tide_report_github_refresh_seconds
    set -l timeout_sec (math --scale=0 "$tide_report_service_timeout_millis / 1000")

    # --- Async Logic ---
    set -l trigger_fetch false
    set -l output_valid false
    set -l now (date +%s)

    # Check cache status
    if test -f "$cache_file"
        set -l mod_time (date -r "$cache_file" +%s 2>/dev/null; or echo 0)
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

    # Trigger background fetch if needed
    if test "$trigger_fetch" = true
        # Generate a safe universal variable name for the lock
        set -l clean_key (string replace -a -r '[^a-zA-Z0-9_]' '_' "$cache_key")
        set -l lock_var "_tide_report_gh_lock_$clean_key"

        set -l lock_time 0
        if set -q $lock_var
            set lock_time $$lock_var
        end

        # Only fetch if lock is old (> 120s) or non-existent
        if test (math $now - $lock_time) -gt 120
            set -U $lock_var $now
            mkdir -p "$cache_dir"
            # Pass BOTH the API Slug and the Cache File path
            __tide_report_fetch_github "$api_slug" "$cache_file" "$timeout_sec" "$lock_var" &
        end
    end

    if test "$output_valid" = true
        # Cache is valid (or stale but usable), parse and print
        __tide_report_parse_github "$cache_file"
    else
        # Data is missing, display loading message
        _tide_print_item github (set_color $tide_report_github_unavailable_color)$tide_report_github_unavailable_text
    end
end

# --- Parser Function ---
function __tide_report_parse_github --argument cache_file
    jq -r '[
        .stargazerCount, 
        .forkCount, 
        .watchers.totalCount, 
        .issues.totalCount, 
        .pullRequests.totalCount
    ] | join(" ")' "$cache_file" 2>/dev/null | read -l stars forks watchers issues prs

    if test $status -ne 0
        return
    end

    set -l output "$tide_report_github_icon"

    test "$stars" != 0 && set output "$output"(set_color $tide_report_github_color_stars)" $tide_report_github_icon_stars$stars"
    test "$forks" != 0 && set output "$output"(set_color $tide_report_github_color_forks)" $tide_report_github_icon_forks$forks"
    test "$watchers" != 0 && set output "$output"(set_color $tide_report_github_color_watchers)" $tide_report_github_icon_watchers$watchers"
    test "$issues" != 0 && set output "$output"(set_color $tide_report_github_color_issues)" $tide_report_github_icon_issues$issues"
    test "$prs" != 0 && set output "$output"(set_color $tide_report_github_color_prs)" $tide_report_github_icon_prs$prs"

    if test -n "$output"
        _tide_print_item github (string trim "$output")
    end
end

# --- Fetch GitHub Data (Background Worker) ---
function __tide_report_fetch_github --argument-names api_slug cache_file timeout_sec lock_var
    # Auto-cleanup lock
    function _remove_lock --on-process-exit $fish_pid --on-signal INT --on-signal TERM --inherit-variable lock_var
        set -U -e $lock_var
    end

    set -l temp_file "$cache_file.$fish_pid.tmp"

    # Fetch data and store in temp file
    set -l json_data (gh repo view "$api_slug" --json 'nameWithOwner,stargazerCount,forkCount,issues,pullRequests,watchers' 2>/dev/null)

    # Check if fetch was successful
    if test $status -eq 0 -a -n "$json_data"
        echo "$json_data" >"$temp_file"
        command mv -f "$temp_file" "$cache_file"
    end
end
