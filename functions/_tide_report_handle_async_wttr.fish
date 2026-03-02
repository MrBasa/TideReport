# TideReport :: Weather and Moon async fetch (provider-agnostic)
#
# Normalized cache schemas (all weather providers produce this shape):
#
#   weather.json: temp_c, temp_f, feels_like_c, feels_like_f, condition_code (WWO 113=clear, ...),
#   condition_text, wind_speed_kmh, wind_speed_mph, wind_dir_16 (N, NE, ...), humidity, uv_index,
#   sunrise_utc, sunset_utc (Unix timestamps)
#
#   moon.json: phase ("Full Moon", "New Moon", ...)

# --- Main async handler for the weather cache (used by weather item only) ---
function _tide_report_handle_async_wttr --argument-names item_name cache_file refresh_seconds expire_seconds unavailable_text unavailable_color timeout_sec
    set -l now (command date +%s)
    set -l trigger_fetch false
    set -l cache_valid false

    # Check cache status
    if test -f "$cache_file"
        set -l mod_time (command date -r "$cache_file" +%s 2>/dev/null; or echo 0)
        set -l cache_age (math $now - $mod_time)
        if test $cache_age -le $expire_seconds
            set cache_valid true
            test $cache_age -gt $refresh_seconds && set trigger_fetch true
        else
            set trigger_fetch true
        end
    else
        set trigger_fetch true
    end

    if $trigger_fetch
        set -l lock_var "_tide_report_wttr_lock"
        set -l lock_time (set -q $lock_var; and echo $$lock_var; or echo 0)
        if test (math $now - $lock_time) -gt 120
            set -U $lock_var $now
            set -l resolved ""
            if test "$tide_report_weather_provider" = "openmeteo"; and test -z "$tide_report_weather_location"
                set -l ip_file "$HOME/.cache/tide-report/ip-location"
                if test -f "$ip_file"
                    set -l line (string split '|' (cat "$ip_file" 2>/dev/null; or echo ""))
                    if test (count $line) -ge 3; and test "$line[1]" = "$fish_pid"
                        set -l mtime (command date -r "$ip_file" +%s 2>/dev/null; or echo 0)
                        set -l age (math $now - $mtime)
                        if test $age -le 86400
                            set resolved "$line[2],$line[3]"
                        end
                    end
                end
            end
            set -l parent_pid "$fish_pid"
            begin
                set -gx TIDE_REPORT_PARENT_PID "$parent_pid"
                test -n "$resolved"; and set -gx TIDE_REPORT_RESOLVED_LOCATION "$resolved"
                __tide_report_fetch_weather "$cache_file" "$timeout_sec" "$lock_var"
            end &
            disown
        end
    end

    if $cache_valid
        return 0
    else
        _tide_print_item $item_name (set_color $unavailable_color)$unavailable_text
        return 1
    end
end

# --- Dispatch by provider ---
function __tide_report_fetch_weather --argument-names weather_cache timeout_sec lock_var
    function _remove_lock --on-process-exit $fish_pid --on-signal INT --on-signal TERM --inherit-variable lock_var
        set -e $lock_var
    end

    switch "$tide_report_weather_provider"
        case wttr
            __tide_report_provider_wttr "$weather_cache" "$timeout_sec" "$lock_var"
        case openmeteo
            __tide_report_provider_openmeteo "$weather_cache" "$timeout_sec" "$lock_var"
        case '*'
            __tide_report_provider_wttr "$weather_cache" "$timeout_sec" "$lock_var"
    end
end

# --- wttr.in provider: one j1 request fills weather.json + moon.json ---
function __tide_report_provider_wttr --argument-names weather_cache timeout_sec lock_var
    set -l url "$tide_report_wttr_url/$tide_report_weather_location?format=j1&lang=$tide_report_weather_language"
    set -l fetched_data (curl -s -A "tide-report/1.0" --max-time $timeout_sec "$url")
    if test $status -ne 0; or test -z "$fetched_data"
        return
    end
    if not printf "%s" "$fetched_data" | jq -e '.current_condition | length > 0' >/dev/null ^/dev/null
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
    if test -n "$normalized"; and printf "%s" "$normalized" | jq -e '.temp_c != null' >/dev/null ^/dev/null
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

# --- Open-Meteo provider ---
# Resolved location can come from: env TIDE_REPORT_RESOLVED_LOCATION (lat,lon),
# IP geo when location empty, lat,lon pattern in tide_report_weather_location, or geocoding API.
function __tide_report_provider_openmeteo --argument-names weather_cache timeout_sec lock_var
    set -l lat ""
    set -l lon ""
    set -l tz "auto"

    if set -q TIDE_REPORT_RESOLVED_LOCATION; and test -n "$TIDE_REPORT_RESOLVED_LOCATION"
        set -l parts (string split ',' -- $TIDE_REPORT_RESOLVED_LOCATION)
        if test (count $parts) -ge 2
            set lat (string trim -- $parts[1])
            set lon (string trim -- $parts[2])
        end
    else if test -z "$tide_report_weather_location"
        set -l ip_data (curl -s -A "tide-report/1.0" --max-time 5 "http://ip-api.com/json/?fields=lat,lon")
        if test $status -eq 0; and test -n "$ip_data"
            set lat (printf "%s" "$ip_data" | jq -r '.lat // empty')
            set lon (printf "%s" "$ip_data" | jq -r '.lon // empty')
            if test -n "$lat"; and test -n "$lon"
                set -l ip_file "$HOME/.cache/tide-report/ip-location"
                if set -q TIDE_REPORT_PARENT_PID; and test -n "$TIDE_REPORT_PARENT_PID"
                    mkdir -p (dirname "$ip_file")
                    printf "%s|%s|%s\n" "$TIDE_REPORT_PARENT_PID" "$lat" "$lon" > "$ip_file"
                end
            end
        end
    else if string match -qr '^-?[0-9]+\.?[0-9]*,-?[0-9]+\.?[0-9]*$' -- (string trim -- "$tide_report_weather_location")
        set -l parts (string split ',' -- (string trim -- "$tide_report_weather_location"))
        set lat (string trim -- $parts[1])
        set lon (string trim -- $parts[2])
    else
        set -l location_escaped (string escape --style url "$tide_report_weather_location")
        set -l geo_url "https://geocoding-api.open-meteo.com/v1/search?name=$location_escaped&count=1"
        set -l geo_data (curl -s -A "tide-report/1.0" --max-time $timeout_sec "$geo_url")
        if test $status -ne 0; or test -z "$geo_data"
            return
        end
        set lat (printf "%s" "$geo_data" | jq -r '.results[0].latitude // empty')
        set lon (printf "%s" "$geo_data" | jq -r '.results[0].longitude // empty')
        set tz (printf "%s" "$geo_data" | jq -r '.results[0].timezone // "auto"')
    end

    if test -z "$lat"; or test -z "$lon"
        return
    end
    set -l tz_escaped (string escape --style url "$tz")
    set -l forecast_url "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,wind_direction_10m,uv_index,apparent_temperature&daily=sunrise,sunset&timezone=$tz_escaped"
    set -l forecast_data (curl -s -A "tide-report/1.0" --max-time $timeout_sec "$forecast_url")
    if test $status -ne 0; or test -z "$forecast_data"
        return
    end
    if not printf "%s" "$forecast_data" | jq -e '.current.temperature_2m != null' >/dev/null ^/dev/null
        return
    end
    set -l tc (printf "%s" "$forecast_data" | jq -r '.current.temperature_2m')
    set -l tf (math "floor($tc * 9 / 5 + 32 + 0.5)")
    set -l fc (printf "%s" "$forecast_data" | jq -r '.current.apparent_temperature // .current.temperature_2m')
    set -l ff (math "floor($fc * 9 / 5 + 32 + 0.5)")
    set -l wmo (printf "%s" "$forecast_data" | jq -r '.current.weather_code')
    set -l cc (__tide_report_wmo_to_condition_code "$wmo")
    set -l ct (__tide_report_wmo_to_condition_text "$wmo")
    set -l wk (printf "%s" "$forecast_data" | jq -r '.current.wind_speed_10m')
    set -l wm (math "floor($wk * 0.621371 + 0.5)")
    set -l deg (printf "%s" "$forecast_data" | jq -r '.current.wind_direction_10m')
    set -l wd (__tide_report_degrees_to_16point "$deg")
    set -l hu (printf "%s" "$forecast_data" | jq -r '.current.relative_humidity_2m')
    set -l uv (printf "%s" "$forecast_data" | jq -r '.current.uv_index // 0')
    set -l sunrise_iso (printf "%s" "$forecast_data" | jq -r '.daily.sunrise[0] // ""')
    set -l sunset_iso (printf "%s" "$forecast_data" | jq -r '.daily.sunset[0] // ""')
    set -l su ""
    set -l sv ""
    if test -n "$sunrise_iso"
        set su (__tide_report_iso8601_to_unix "$sunrise_iso")
    end
    if test -n "$sunset_iso"
        set sv (__tide_report_iso8601_to_unix "$sunset_iso")
    end
    set -l su (string trim -- $su)
    set -l sv (string trim -- $sv)
    set ct (string replace '\\' '\\\\' -- $ct)
    set ct (string replace '"' '\\"' -- $ct)
    set -l normalized (jq -n \
        --argjson tc $tc --argjson tf $tf --argjson fc $fc --argjson ff $ff \
        --argjson cc $cc --arg ct "$ct" --argjson wk $wk --argjson wm $wm \
        --arg wd "$wd" --argjson hu $hu --argjson uv $uv \
        --arg su "$su" --arg sv "$sv" \
        '{temp_c:$tc,temp_f:$tf,feels_like_c:$fc,feels_like_f:$ff,condition_code:$cc,condition_text:$ct,wind_speed_kmh:$wk,wind_speed_mph:$wm,wind_dir_16:$wd,humidity:$hu,uv_index:$uv,sunrise_utc:(if $su=="" then null else ($su|tonumber) end),sunset_utc:(if $sv=="" then null else ($sv|tonumber) end)}')
    if test -n "$normalized"; and printf "%s" "$normalized" | jq -e '.temp_c != null' >/dev/null ^/dev/null
        mkdir -p (dirname "$weather_cache")
        set -l temp_file "$weather_cache.$fish_pid.tmp"
        printf "%s" "$normalized" > "$temp_file" && command mv -f "$temp_file" "$weather_cache"
    end
end

# --- WMO weather code → our condition_code (WWO 113, 116, ...) ---
function __tide_report_wmo_to_condition_code --argument-names wmo
    switch "$wmo"
        case 0; echo 113
        case 1 2; echo 116
        case 3; echo 122
        case 45 48; echo 143
        case 51 53 55 56 57 61 63 65 66 67 80 81 82; echo 296
        case 71 73 75 77 85 86; echo 338
        case 95 96 99; echo 200
        case '*'; echo 119
    end
end

# --- WMO → short condition text ---
function __tide_report_wmo_to_condition_text --argument-names wmo
    switch "$wmo"
        case 0; echo "Clear"
        case 1; echo "Mainly clear"
        case 2; echo "Partly cloudy"
        case 3; echo "Overcast"
        case 45 48; echo "Foggy"
        case 51 53 55; echo "Drizzle"
        case 56 57; echo "Freezing drizzle"
        case 61 63 65; echo "Rain"
        case 66 67; echo "Freezing rain"
        case 71 73 75; echo "Snow"
        case 77; echo "Snow grains"
        case 80 81 82; echo "Rain showers"
        case 85 86; echo "Snow showers"
        case 95 96 99; echo "Thunderstorm"
        case '*'; echo "Unknown"
    end
end

# --- Wind direction degrees → 16-point compass ---
function __tide_report_degrees_to_16point --argument-names deg
    set -l d (math "floor($deg + 11.25) % 360 / 22.5")
    switch $d
        case 0; echo "N"
        case 1; echo "NNE"
        case 2; echo "NE"
        case 3; echo "ENE"
        case 4; echo "E"
        case 5; echo "ESE"
        case 6; echo "SE"
        case 7; echo "SSE"
        case 8; echo "S"
        case 9; echo "SSW"
        case 10; echo "SW"
        case 11; echo "WSW"
        case 12; echo "W"
        case 13; echo "WNW"
        case 14; echo "NW"
        case 15; echo "NNW"
        case '*'; echo "N"
    end
end

# --- ISO8601 string → Unix timestamp ---
function __tide_report_iso8601_to_unix --argument-names iso
    if test -z "$iso"
        echo ""
        return
    end
    if command -q gdate
        gdate -d "$iso" +%s 2>/dev/null
    else if command date --version >/dev/null ^/dev/null
        command date -d "$iso" +%s 2>/dev/null
    else
        set -l parts (string split 'T' -- $iso)
        if test (count $parts) -ge 2
            command date -j -f "%Y-%m-%dT%H:%M" "$parts[1]T$parts[2]" +%s 2>/dev/null
        end
    end
end

# --- Moon async handler: owns moon.json; when stale, calls wttr provider (if wttr) or moon-only fetch ---
function _tide_report_handle_async_moon --argument-names item_name cache_file refresh_seconds expire_seconds unavailable_text unavailable_color timeout_sec
    set -l now (command date +%s)
    set -l trigger_fetch false
    set -l cache_valid false

    if test -f "$cache_file"
        set -l mod_time (command date -r "$cache_file" +%s 2>/dev/null; or echo 0)
        set -l cache_age (math $now - $mod_time)
        if test $cache_age -le $expire_seconds
            set cache_valid true
            test $cache_age -gt $refresh_seconds && set trigger_fetch true
        else
            set trigger_fetch true
        end
    else
        set trigger_fetch true
    end

    if $trigger_fetch
        set -l lock_var "_tide_report_wttr_lock"
        set -l lock_time (set -q $lock_var; and echo $$lock_var; or echo 0)
        if test (math $now - $lock_time) -gt 120
            set -U $lock_var $now
            if test "$tide_report_weather_provider" = "wttr"
                set -l weather_cache "$HOME/.cache/tide-report/weather.json"
                __tide_report_fetch_weather "$weather_cache" "$timeout_sec" "$lock_var" &
            else
                __tide_report_fetch_moon_only "$cache_file" "$timeout_sec" "$lock_var" &
            end
            disown
        end
    end

    if $cache_valid
        return 0
    else
        _tide_print_item $item_name (set_color $unavailable_color)$unavailable_text
        return 1
    end
end

# --- Moon-only fetch (when weather provider is not wttr) ---
function __tide_report_fetch_moon_only --argument-names moon_cache timeout_sec lock_var
    function _remove_lock_moon --on-process-exit $fish_pid --on-signal INT --on-signal TERM --inherit-variable lock_var
        set -e $lock_var
    end

    set -l url "$tide_report_wttr_url/$tide_report_weather_location?format=j1&lang=$tide_report_weather_language"
    set -l fetched_data (curl -s -A "tide-report/1.0" --max-time $timeout_sec "$url")
    if test $status -ne 0; or test -z "$fetched_data"
        return
    end
    set -l phase (printf "%s" "$fetched_data" | jq -r '.weather[0].astronomy[0].moon_phase // ""')
    if test -n "$phase"
        set -l moon_json (jq -n --arg phase "$phase" '{phase:$phase}')
        mkdir -p (dirname "$moon_cache")
        set -l moon_temp "$moon_cache.$fish_pid.tmp"
        printf "%s" "$moon_json" > "$moon_temp" && command mv -f "$moon_temp" "$moon_cache"
    end
end
