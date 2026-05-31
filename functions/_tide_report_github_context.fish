## TideReport :: GitHub context and cache path helpers

function __tide_report_github_path_within --description "Return success when path is inside repo_root" --argument-names candidate repo_root
    test -n "$candidate"; and test -n "$repo_root"; or return 1
    if test "$candidate" = "$repo_root"
        return 0
    end
    string match -q -- "$repo_root/*" "$candidate"
end

function __tide_report_github_file_mtime --description "Return file mtime using Fish builtins (alias of __tide_report_file_mtime)" --argument-names file_path
    if not functions -q __tide_report_file_mtime
        source (status filename | path dirname)/_tide_report_cache_helpers.fish
    end
    __tide_report_file_mtime "$file_path"
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

function __tide_report_github_auth_ok --description "Return whether gh is authenticated for github.com (session-cached)"
    if set -q __tide_report_github_auth_ok
        test "$__tide_report_github_auth_ok" = 1
        return $status
    end
    if gh auth status -h github.com 2>/dev/null
        set -g __tide_report_github_auth_ok 1
        return 0
    end
    set -g __tide_report_github_auth_ok 0
    return 1
end

function __tide_report_github_unavailable_display --description "Unavailable segment text; appends !auth when gh is not authenticated"
    set -l text $tide_report_github_unavailable_text
    if not __tide_report_github_auth_ok
        set text "$text!auth"
    end
    echo "$text"
end

function __tide_report_github_ci_display_state --description "Map CI cache age and fetch state to display state (pass|fail|pending|none)" --argument-names cached_ci_state ci_age ci_refresh_seconds ci_expire_seconds ci_fetch_in_flight
    if test "$ci_fetch_in_flight" = true
        echo pending
        return 0
    end
    if test "$ci_age" -lt 0
        echo none
        return 0
    end
    if test "$ci_age" -gt $ci_expire_seconds
        echo none
        return 0
    end
    if test "$ci_age" -gt $ci_refresh_seconds
        echo pending
        return 0
    end
    echo "$cached_ci_state"
end

function __tide_report_github_ci_effective_refresh --description "Return CI cache refresh interval based on state and in-flight fetch" --argument-names cached_ci_state ci_lock_var
    set -q tide_report_github_ci_refresh_seconds; or set -l tide_report_github_ci_refresh_seconds 60
    set -q tide_report_github_ci_running_refresh_seconds; or set -l tide_report_github_ci_running_refresh_seconds 5

    if test "$cached_ci_state" = pending
        echo $tide_report_github_ci_running_refresh_seconds
        return 0
    end

    if test -n "$ci_lock_var"
        if not functions -q __tide_report_lock_held
            source (status filename | path dirname)/_tide_report_lock_helpers.fish
        end
        if __tide_report_lock_held "$ci_lock_var"
            echo $tide_report_github_ci_running_refresh_seconds
            return 0
        end
    end

    echo $tide_report_github_ci_refresh_seconds
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


function __tide_report_github_context --description "Resolve repo/cache metadata and cache it per repo root"
    if set -q __tide_report_github_context_repo_root
        set -l current_dir (path resolve "$PWD" 2>/dev/null | string collect)
        test -n "$current_dir"; or set current_dir (path normalize "$PWD")
        if __tide_report_github_path_within "$current_dir" "$__tide_report_github_context_repo_root"
            printf "%s\n" $__tide_report_github_context_values
            return 0
        end
    end

    if not functions -q __tide_report_github_context_resolve
        source (status filename | path dirname)/_tide_report_github_discover.fish
    end
    set -l resolved (__tide_report_github_context_resolve "$PWD")
    if test (count $resolved) -lt 3
        return 1
    end
    set -l repo_root $resolved[1]
    set -l git_dir $resolved[2]
    set -l remote_url $resolved[3]
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
