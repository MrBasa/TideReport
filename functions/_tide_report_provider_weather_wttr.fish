## TideReport :: wttr.in weather provider
## One j1 request fills weather.json + moon.json. Requires __tide_report_time_string_to_unix (from weather item).

function __tide_report_provider_wttr --description "Fetch weather and moon data from wttr.in and normalize to JSON caches" --argument-names weather_cache timeout_sec lock_var
    set -l url "$tide_report_wttr_url/$tide_report_weather_location?format=j1&lang=$tide_report_weather_language"
    set -l fetched_data (curl -s -A "$tide_report_user_agent" --max-time $timeout_sec "$url")
    if test $status -ne 0; or test -z "$fetched_data"
        return
    end
    if not printf "%s" "$fetched_data" | jq -e '.current_condition | length > 0' 2>/dev/null >/dev/null
        return
    end

    set -l moon_cache "$HOME/.cache/tide-report/moon.json"
    set -l dir (dirname "$weather_cache")
    mkdir -p "$dir"

    # Parse sunrise/sunset "07:30 AM" to Unix (today local)
    set -l sunrise_str (printf "%s" "$fetched_data" | jq -r '.weather[0].astronomy[0].sunrise // ""')
    set -l sunset_str (printf "%s" "$fetched_data" | jq -r '.weather[0].astronomy[0].sunset // ""')
    set -l sunrise_utc ""
    set -l sunset_utc ""
    if test -n "$sunrise_str"
        set sunrise_utc (__tide_report_time_string_to_unix (string trim -- $sunrise_str))
    end
    if test -n "$sunset_str"
        set sunset_utc (__tide_report_time_string_to_unix (string trim -- $sunset_str))
    end

    # Build normalized weather JSON from j1
    set -l tc (printf "%s" "$fetched_data" | jq -r '.current_condition[0].temp_C')
    set -l tf (printf "%s" "$fetched_data" | jq -r '.current_condition[0].temp_F')
    set -l fc (printf "%s" "$fetched_data" | jq -r '.current_condition[0].FeelsLikeC')
    set -l ff (printf "%s" "$fetched_data" | jq -r '.current_condition[0].FeelsLikeF')
    set -l cc (printf "%s" "$fetched_data" | jq -r '.current_condition[0].weatherCode')
    set -l ct (printf "%s" "$fetched_data" | jq -r '.current_condition[0].weatherDesc[0].value')
    set -l wk (printf "%s" "$fetched_data" | jq -r '.current_condition[0].windspeedKmph')
    set -l wm (printf "%s" "$fetched_data" | jq -r '.current_condition[0].windspeedMiles')
    set -l wd (printf "%s" "$fetched_data" | jq -r '.current_condition[0].winddir16Point')
    set -l hu (printf "%s" "$fetched_data" | jq -r '.current_condition[0].humidity')
    set -l uv (printf "%s" "$fetched_data" | jq -r '.current_condition[0].uvIndex')
    set -l su (string trim -- $sunrise_utc)
    set -l sv (string trim -- $sunset_utc)
    # Escape condition_text for JSON (backslash then double-quote)
    set ct (string replace '\\' '\\\\' -- $ct)
    set ct (string replace '"' '\\"' -- $ct)
    set -l normalized (jq -n \
        --argjson tc $tc --argjson tf $tf --argjson fc $fc --argjson ff $ff \
        --argjson cc $cc --arg ct "$ct" --argjson wk $wk --argjson wm $wm \
        --arg wd "$wd" --argjson hu $hu --argjson uv $uv \
        --arg su "$su" --arg sv "$sv" \
        '{temp_c:$tc,temp_f:$tf,feels_like_c:$fc,feels_like_f:$ff,condition_code:$cc,condition_text:$ct,wind_speed_kmh:$wk,wind_speed_mph:$wm,wind_dir_16:$wd,humidity:$hu,uv_index:$uv,sunrise_utc:(if $su=="" then null else ($su|tonumber) end),sunset_utc:(if $sv=="" then null else ($sv|tonumber) end)}')
    if test -n "$normalized"; and printf "%s" "$normalized" | jq -e '.temp_c != null' 2>/dev/null >/dev/null
        set -l temp_file "$weather_cache.$fish_pid.tmp"
        printf "%s" "$normalized" > "$temp_file" && command mv -f "$temp_file" "$weather_cache"
    end

    # Moon cache (use jq for safe escaping)
    set -l phase (printf "%s" "$fetched_data" | jq -r '.weather[0].astronomy[0].moon_phase // ""')
    if test -n "$phase"
        set -l moon_json (jq -n --arg phase "$phase" '{phase:$phase}')
        set -l moon_temp "$moon_cache.$fish_pid.tmp"
        printf "%s" "$moon_json" > "$moon_temp" && command mv -f "$moon_temp" "$moon_cache"
    end
end
