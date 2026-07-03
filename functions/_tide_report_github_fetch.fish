## TideReport :: GitHub background fetch workers

function __tide_report_run_gh --description "Run gh with optional timeout wrapper" --argument-names timeout_sec
    set -l gh_argv $argv[2..-1]
    if test -n "$timeout_sec"; and test "$timeout_sec" -gt 0; and command -q timeout
        command timeout "$timeout_sec"s gh $gh_argv
    else
        gh $gh_argv
    end
end

function __tide_report_fetch_github --description "Fetch GitHub repo stats with gh and write cache JSON" --argument-names api_slug cache_file timeout_sec lock_var
    if not functions -q __tide_report_lock_release
        source (status filename | path dirname)/_tide_report_lock_helpers.fish
    end
    if not functions -q __tide_report_github_stats_line_valid
        source (status filename | path dirname)/_tide_report_github_context.fish
    end
    if not functions -q __tide_report_github_stats_file
        source (status filename | path dirname)/_tide_report_github_context.fish
    end

    function _remove_lock --description "Clear GitHub fetch lock when background worker exits" --on-process-exit $fish_pid --on-signal INT --on-signal TERM --inherit-variable lock_var
        __tide_report_lock_release "$lock_var"
    end

    set -l temp_file "$cache_file.$fish_pid.tmp"
    set -l stats_file (__tide_report_github_stats_file "$cache_file")
    set -l stats_temp "$stats_file.$fish_pid.tmp"

    set -l json_data (__tide_report_run_gh "$timeout_sec" repo view "$api_slug" --json 'nameWithOwner,stargazerCount,forkCount,issues,pullRequests,watchers' 2>/dev/null)
    set -l fetch_status $status
    set -l stats_line ""
    if test $fetch_status -eq 0; and test -n "$json_data"
        set stats_line (printf "%s" "$json_data" | command jq -r '[.stargazerCount,.forkCount,.watchers.totalCount,.issues.totalCount,.pullRequests.totalCount]|join(" ")' 2>/dev/null)
    end

    if test $fetch_status -eq 0; and test -n "$json_data"; and __tide_report_github_stats_line_valid "$stats_line"
        printf "%s\n" "$json_data" >"$temp_file"
        printf "%s\n" "$stats_line" >"$stats_temp"
        command mv -f "$temp_file" "$cache_file"
        command mv -f "$stats_temp" "$stats_file"
    else
        command rm -f "$temp_file" "$stats_temp" 2>/dev/null
        if functions -q _tide_report_log_expected
            if not __tide_report_github_auth_ok
                _tide_report_log_expected github "gh not authenticated"
            else
                _tide_report_log_expected github "fetch failed (network or gh error)"
            end
        end
    end
end

function __tide_report_fetch_github_ci --description "Fetch latest workflow run for branch and write CI cache JSON" --argument-names api_slug branch ci_cache_file timeout_sec lock_var
    if not functions -q __tide_report_lock_release
        source (status filename | path dirname)/_tide_report_lock_helpers.fish
    end
    if not functions -q __tide_report_github_state_file
        source (status filename | path dirname)/_tide_report_github_context.fish
    end
    if not functions -q __tide_report_github_ci_state_valid
        source (status filename | path dirname)/_tide_report_github_context.fish
    end

    function _remove_ci_lock --description "Clear GitHub CI fetch lock when background worker exits" --on-process-exit $fish_pid --on-signal INT --on-signal TERM --inherit-variable lock_var
        __tide_report_lock_release "$lock_var"
    end

    set -l temp_file "$ci_cache_file.$fish_pid.tmp"
    set -l state_file (__tide_report_github_state_file "$ci_cache_file")
    set -l state_temp "$state_file.$fish_pid.tmp"
    set -l json_data (__tide_report_run_gh "$timeout_sec" run list -R "$api_slug" -b "$branch" -L 1 --json status,conclusion,name 2>/dev/null)
    set -l fetch_status $status
    set -l ci_state ""
    if test $fetch_status -eq 0; and test -n "$json_data"
        set ci_state (printf "%s" "$json_data" | command jq -r 'if length == 0 then "none" else (.[0] | if .status == "completed" then (if .conclusion == "success" then "pass" else "fail" end) else "pending" end) end' 2>/dev/null)
    end

    if test $fetch_status -eq 0; and test -n "$json_data"; and __tide_report_github_ci_state_valid "$ci_state"
        printf "%s\n" "$json_data" >"$temp_file"
        printf "%s\n" "$ci_state" >"$state_temp"
        command mv -f "$temp_file" "$ci_cache_file"
        command mv -f "$state_temp" "$state_file"
    else
        command rm -f "$temp_file" "$state_temp" 2>/dev/null
        if functions -q _tide_report_log_expected
            if not __tide_report_github_auth_ok
                _tide_report_log_expected github "gh not authenticated (CI fetch)"
            else
                _tide_report_log_expected github "CI fetch failed (network or gh error)"
            end
        end
    end
end
