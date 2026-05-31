## TideReport :: Open-Meteo weather provider
## Resolved location can come from: env TIDE_REPORT_RESOLVED_LOCATION (lat,lon),
## IP geo when location empty, lat,lon pattern in tide_report_weather_location, or geocoding API.

if not functions -q __tide_report_iso8601_to_unix
    source (status filename | path dirname)/_tide_report_time_helpers.fish
end
if not functions -q __tide_report_openmeteo_resolve_location
    source (status filename | path dirname)/_tide_report_weather_helpers.fish
end
if not functions -q __tide_report_write_json_cache
    source (status filename | path dirname)/_tide_report_cache_helpers.fish
end

function __tide_report_provider_openmeteo --description "Fetch weather from Open-Meteo, normalize, and write weather.json" --argument-names weather_cache timeout_sec lock_var
    if not set resolved (__tide_report_openmeteo_resolve_location "$tide_report_weather_location" "$timeout_sec" true)
        functions -q __tide_report_log_expected && __tide_report_log_expected weather "geocoding failed or invalid location"
        return
    end
    set -l lat $resolved[1]
    set -l lon $resolved[2]
    set -l tz $resolved[3]

    set -l tz_escaped (string escape --style url "$tz")
    set -l forecast_url "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,wind_direction_10m,uv_index,apparent_temperature&daily=sunrise,sunset&timezone=$tz_escaped"
    set -l forecast_data (curl -s -A "$tide_report_user_agent" --max-time $timeout_sec "$forecast_url")
    if test $status -ne 0; or test -z "$forecast_data"
        functions -q __tide_report_log_expected && __tide_report_log_expected weather "API unavailable or invalid response"
        return
    end
    if not printf "%s" "$forecast_data" | jq -e '.current.temperature_2m != null' 2>/dev/null >/dev/null
        functions -q __tide_report_log_expected && __tide_report_log_expected weather "API unavailable or invalid response"
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
    set -l normalized (__tide_report_build_weather_normalized_json $tc $tf $fc $ff $cc "$ct" $wk $wm "$wd" $hu $uv "$su" "$sv")
    if test -n "$normalized"; and printf "%s" "$normalized" | jq -e '.temp_c != null' 2>/dev/null >/dev/null
        __tide_report_write_json_cache "$weather_cache" "$normalized"
    end
end

## --- WMO weather code → our condition_code (WWO 113, 116, ...) ---
function __tide_report_wmo_to_condition_code --description "Map Open-Meteo WMO code to our condition_code" --argument-names wmo
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

## --- WMO → short condition text ---
function __tide_report_wmo_to_condition_text --description "Map Open-Meteo WMO code to a short condition text" --argument-names wmo
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

## --- Wind direction degrees → 16-point compass ---
function __tide_report_degrees_to_16point --description "Convert wind direction in degrees to 16-point compass value" --argument-names deg
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
