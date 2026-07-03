## TideReport :: Detached fish subprocess spawns for background cache fetches
##
## Fish does not reliably background function calls with `&`; external `fish script &` does.

function __tide_report_spawn_config_lines --description "Build set -g lines for present TideReport config variables" --argument-names names
    set -l out
    for v in $names
        if set -q $v
            set -a out "set -g $v "(string escape --style script -- $$v)
        end
    end
    echo $out
end

function __tide_report_spawn_common_config --description "Config vars passed to detached fetch subprocesses"
    __tide_report_spawn_config_lines \
        HOME PATH \
        tide_report_user_agent tide_report_log_expected \
        tide_report_weather_provider tide_report_weather_location \
        tide_report_wttr_url tide_report_weather_language tide_report_units \
        tide_report_moon_provider tide_report_service_timeout_millis \
        tide_report_tide_station_id
end

function __tide_report_spawn_fish_script --description "Run a fish script in a detached subprocess" --argument-names script_path
    command fish $script_path >/dev/null 2>&1 &
    disown 2>/dev/null
end

function __tide_report_spawn_write_script --description "Write spawn script lines and launch detached fish" --argument-names spawn_path source_file func_name
    set -l dir (status filename | path dirname)
    mkdir -p (dirname "$spawn_path")

    set -l lines
    set -a lines "#!/usr/bin/env fish"
    set -a lines "set -g fish_function_path "(string escape --style script -- "$dir")" \$fish_function_path"
    set -a lines (__tide_report_spawn_common_config)
    set -a lines "source "(string escape --style script -- "$dir/$source_file")
    set -l call "$func_name"
    for arg in $argv[4..-1]
        set call "$call "(string escape --style script -- "$arg")
    end
    set -a lines $call
    set -a lines "command rm -f "(string escape --style script -- "$spawn_path")

    printf '%s\n' $lines >"$spawn_path"
    __tide_report_spawn_fish_script "$spawn_path"
end

function __tide_report_spawn_call --description "Run a TideReport function in a detached fish subprocess" --argument-names source_file func_name
    set -l spawn "$HOME/.cache/tide-report/spawn-$func_name-$fish_pid.fish"
    __tide_report_spawn_write_script "$spawn" "$source_file" "$func_name" $argv[3..-1]
end

function __tide_report_spawn_weather_fetch --description "Refresh weather.json in a detached fish subprocess" --argument-names cache_file timeout_sec lock_var parent_pid resolved
    set -l dir (status filename | path dirname)
    set -l spawn "$HOME/.cache/tide-report/spawn-weather-$fish_pid.fish"
    mkdir -p (dirname "$spawn")

    set -l lines
    set -a lines "#!/usr/bin/env fish"
    set -a lines "set -g fish_function_path "(string escape --style script -- "$dir")" \$fish_function_path"
    set -a lines (__tide_report_spawn_common_config)
    set -a lines "source "(string escape --style script -- "$dir/_tide_report_handle_async_weather.fish")
    if test -n "$parent_pid"
        set -a lines "set -gx TIDE_REPORT_PARENT_PID "(string escape --style script -- "$parent_pid")
    end
    if test -n "$resolved"
        set -a lines "set -gx TIDE_REPORT_RESOLVED_LOCATION "(string escape --style script -- "$resolved")
    end
    set -a lines "__tide_report_fetch_weather "(string escape --style script -- "$cache_file")" $timeout_sec "(string escape --style script -- "$lock_var")
    set -a lines "command rm -f "(string escape --style script -- "$spawn")

    printf '%s\n' $lines >"$spawn"
    __tide_report_spawn_fish_script "$spawn"
end

function __tide_report_spawn_github_fetch --description "Fetch GitHub repo stats in a detached fish subprocess" --argument-names api_slug cache_file timeout_sec lock_var
    __tide_report_spawn_call "_tide_report_github_fetch.fish" __tide_report_fetch_github \
        "$api_slug" "$cache_file" "$timeout_sec" "$lock_var"
end

function __tide_report_spawn_github_ci_fetch --description "Fetch GitHub CI status in a detached fish subprocess" --argument-names api_slug branch ci_cache_file timeout_sec lock_var
    __tide_report_spawn_call "_tide_report_github_fetch.fish" __tide_report_fetch_github_ci \
        "$api_slug" "$branch" "$ci_cache_file" "$timeout_sec" "$lock_var"
end

function __tide_report_spawn_moon_wttr_fetch --description "Fetch moon phase from wttr.in in a detached fish subprocess" --argument-names moon_cache timeout_sec lock_var
    __tide_report_spawn_call "_tide_report_provider_moon_wttr.fish" __tide_report_provider_moon_wttr \
        "$moon_cache" "$timeout_sec" "$lock_var"
end

function __tide_report_spawn_tide_fetch --description "Fetch tide predictions from NOAA in a detached fish subprocess" --argument-names url cache_file lock_var timeout_sec
    __tide_report_spawn_call "_tide_report_tide_helpers.fish" __tide_report_fetch_tide \
        "$url" "$cache_file" "$lock_var" "$timeout_sec"
end
