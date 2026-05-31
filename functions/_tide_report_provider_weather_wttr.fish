## TideReport :: wttr.in weather provider
## One j1 request fills weather.json + moon.json. Requires __tide_report_time_string_to_unix (from weather item).

if not functions -q __tide_report_time_string_to_unix
    source (status filename | path dirname)/_tide_report_time_helpers.fish
end
if not functions -q __tide_report_build_weather_normalized_json_from_wttr_extract
    source (status filename | path dirname)/_tide_report_weather_helpers.fish
end
if not functions -q __tide_report_write_json_cache
    source (status filename | path dirname)/_tide_report_cache_helpers.fish
end

function __tide_report_provider_weather_wttr --description "Fetch weather and moon data from wttr.in and normalize to JSON caches" --argument-names weather_cache timeout_sec lock_var
    set -l url "$tide_report_wttr_url/$tide_report_weather_location?format=j1&lang=$tide_report_weather_language"
    set -l fetched_data (curl -s -A "$tide_report_user_agent" --max-time $timeout_sec "$url")
    if test $status -ne 0; or test -z "$fetched_data"
        functions -q _tide_report_log_expected && _tide_report_log_expected weather "wttr.in unavailable or invalid response"
        return
    end

    set -l extracted (printf "%s" "$fetched_data" | jq -e -c '
        if (.current_condition | length) == 0 then
            error("invalid")
        else
            {
                sunrise_str: (.weather[0].astronomy[0].sunrise // ""),
                sunset_str: (.weather[0].astronomy[0].sunset // ""),
                moon_phase: (.weather[0].astronomy[0].moon_phase // ""),
                tc: .current_condition[0].temp_C,
                tf: .current_condition[0].temp_F,
                fc: .current_condition[0].FeelsLikeC,
                ff: .current_condition[0].FeelsLikeF,
                cc: .current_condition[0].weatherCode,
                ct: .current_condition[0].weatherDesc[0].value,
                wk: .current_condition[0].windspeedKmph,
                wm: .current_condition[0].windspeedMiles,
                wd: .current_condition[0].winddir16Point,
                hu: .current_condition[0].humidity,
                uv: .current_condition[0].uvIndex
            }
        end
    ' 2>/dev/null)
    if test $status -ne 0; or test -z "$extracted"
        functions -q _tide_report_log_expected && _tide_report_log_expected weather "wttr.in unavailable or invalid response"
        return
    end

    set -l moon_cache "$HOME/.cache/tide-report/moon.json"

    set -l sunrise_str (string match -r '"sunrise_str":"([^"]*)"' -- "$extracted" | tail -1)
    set -l sunset_str (string match -r '"sunset_str":"([^"]*)"' -- "$extracted" | tail -1)
    set -l moon_phase (string match -r '"moon_phase":"([^"]*)"' -- "$extracted" | tail -1)

    set -l sunrise_utc ""
    set -l sunset_utc ""
    if test -n "$sunrise_str"
        set sunrise_utc (__tide_report_time_string_to_unix (string trim -- $sunrise_str))
    end
    if test -n "$sunset_str"
        set sunset_utc (__tide_report_time_string_to_unix (string trim -- $sunset_str))
    end

    set -l normalized (__tide_report_build_weather_normalized_json_from_wttr_extract "$extracted" "$sunrise_utc" "$sunset_utc")
    if test -n "$normalized"; and string match -qr '"temp_c":[0-9-]' -- "$normalized"
        __tide_report_write_json_cache "$weather_cache" "$normalized"
    end

    if test -n "$moon_phase"
        set -l moon_json (jq -n --arg phase "$moon_phase" '{phase:$phase}')
        __tide_report_write_json_cache "$moon_cache" "$moon_json"
    end
end
