function _tide_report_sub_bug-report --description "Print environment snapshot for GitHub issues"
    set -q _tide_report_version; or set -l _tide_report_version "?"
    set -q tide_report_user_agent; or set -l tide_report_user_agent "tide-report/?"

    printf '%s\n' "Please copy the following into a new issue:"
    printf '%s\n' "https://github.com/MrBasa/TideReport/issues/new"
    printf '\n%s\n' "--- TideReport ---"
    printf '%s\n' "tide-report version: $_tide_report_version"
    printf '%s\n' "tide_report_user_agent: $tide_report_user_agent"

    for var in tide_report_weather_provider tide_report_moon_provider tide_report_weather_location tide_report_tide_station_id
        if set -q $var
            printf '%s\n' "$var: $$var"
        else
            printf '%s\n' "$var: (unset)"
        end
    end

    set -l timer_vars \
        tide_report_weather_refresh_seconds tide_report_weather_expire_seconds \
        tide_report_moon_refresh_seconds tide_report_moon_expire_seconds \
        tide_report_tide_refresh_seconds tide_report_tide_expire_seconds \
        tide_report_github_refresh_seconds tide_report_github_ci_refresh_seconds tide_report_github_ci_expire_seconds
    for var in $timer_vars
        if set -q $var
            printf '%s\n' "$var: $$var"
        end
    end

    if set -q tide_report_github_show_ci
        printf '%s\n' "tide_report_github_show_ci: $tide_report_github_show_ci"
    end

    if set -q tide_left_prompt_items
        printf '%s\n' "tide_left_prompt_items: $tide_left_prompt_items"
    end
    if set -q tide_right_prompt_items
        printf '%s\n' "tide_right_prompt_items: $tide_right_prompt_items"
    end

    printf '\n%s\n' "--- gh auth status ---"
    if command -v gh >/dev/null 2>&1
        gh auth status -h github.com 2>&1
    else
        printf '%s\n' "gh: not installed"
    end

    if set -q _fisher_plugins
        printf '\n%s\n' "--- fisher ---"
        printf '%s\n' "fisher plugins: $_fisher_plugins"
    end

    set -l state_dir
    if set -q XDG_STATE_HOME; and string length -q -- "$XDG_STATE_HOME"
        set state_dir "$XDG_STATE_HOME"
    else
        set state_dir "$HOME/.local/state"
    end
    set -l log_file "$state_dir/tide-report/tide-report.log"
    if test -f "$log_file"
        printf '\n%s\n' "--- tide-report.log (last 40 lines) ---"
        tail -n 40 "$log_file" 2>/dev/null
    end

    printf '\n%s\n' "--- configuration health ---"
    if not functions -q _tide_report_run_health_checks
        source (status dirname)/_tide_report_health_checks.fish
    end
    _tide_report_run_health_checks for_bug_report
end
