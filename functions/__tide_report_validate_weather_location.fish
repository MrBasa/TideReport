## TideReport :: Validate location for weather (Open-Meteo) and echo resolved display string.
## Used by the install wizard. Accepts lat,lng (forgiving: optional space around comma), city name, or postal code.
## On success: echo one line (resolved display string) to stdout and return 0. On failure: return 1.

if not functions -q __tide_report_openmeteo_resolve_location
    source (status filename | path dirname)/_tide_report_weather_helpers.fish
end

function __tide_report_validate_weather_location --description "Validate location via Open-Meteo; on success echo resolved display string" --argument-names input
    set -l raw (string trim -- "$input")
    if test -z "$raw"
        return 1
    end

    set -l timeout_sec 6
    set -q tide_report_service_timeout_millis && set timeout_sec (math --scale=0 "$tide_report_service_timeout_millis / 1000")

    set -l lat ""
    set -l lon ""
    set -l tz "auto"
    set -l geo_name ""
    set -l admin1 ""
    set -l country ""
    set -l is_coords false

    if set coords (__tide_report_openmeteo_parse_lat_lon "$raw")
        set is_coords true
        set lat $coords[1]
        set lon $coords[2]
    else if set geocoded (__tide_report_openmeteo_geocode "$raw" "$timeout_sec")
        set lat $geocoded[1]
        set lon $geocoded[2]
        set tz $geocoded[3]
        set geo_name $geocoded[4]
        set admin1 $geocoded[5]
        set country $geocoded[6]
    else
        echo (string trim -- "Location not found or geocoding failed.") >&2
        return 1
    end

    set -l tz_escaped (string escape --style url "$tz")
    set -l forecast_url "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m&timezone=$tz_escaped"
    set -l forecast_data (curl -s -A "$tide_report_user_agent" --max-time $timeout_sec "$forecast_url")
    if test $status -ne 0; or test -z "$forecast_data"
        echo (string trim -- "Location not found or weather unavailable.") >&2
        return 1
    end
    if not printf "%s" "$forecast_data" | jq -e '.current.temperature_2m != null' 2>/dev/null >/dev/null
        echo (string trim -- "Weather unavailable for this location.") >&2
        return 1
    end

    if $is_coords
        printf "%s, %s\n" "$lat" "$lon"
    else
        set -l parts $geo_name
        test -n "$admin1" && set parts $parts $admin1
        set parts $parts $country
        printf "%s\n" (string join ", " $parts)
    end
    return 0
end
