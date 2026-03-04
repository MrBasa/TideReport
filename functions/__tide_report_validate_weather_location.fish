## TideReport :: Validate location for weather (Open-Meteo) and echo resolved display string.
## Used by the install wizard. Accepts lat,lng (forgiving: optional space around comma), city name, or postal code.
## On success: echo one line (resolved display string) to stdout and return 0. On failure: return 1.

function __tide_report_validate_weather_location --description "Validate location via Open-Meteo; on success echo resolved display string" --argument-names input
    set -l raw (string trim -- "$input")
    if test -z "$raw"
        return 1
    end

    set -l timeout_sec 6
    set -q tide_report_service_timeout_millis && set timeout_sec (math --scale=0 "$tide_report_service_timeout_millis / 1000")

    ## Forgiving lat,lng: optional whitespace around comma
    if string match -qr '^-?[0-9]+\.?[0-9]*\s*,\s*-?[0-9]+\.?[0-9]*$' -- "$raw"
        set -l parts (string split ',' -- "$raw")
        set -l lat (string trim -- $parts[1])
        set -l lon (string trim -- $parts[2])
        set -l forecast_url "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m&timezone=auto"
        set -l forecast_data (curl -s -A "$tide_report_user_agent" --max-time $timeout_sec "$forecast_url")
        if test $status -ne 0; or test -z "$forecast_data"
            echo (string trim -- "Location not found or weather unavailable.") >&2
            return 1
        end
        if not printf "%s" "$forecast_data" | jq -e '.current.temperature_2m != null' 2>/dev/null >/dev/null
            echo (string trim -- "Weather unavailable for this location.") >&2
            return 1
        end
        printf "%s, %s\n" "$lat" "$lon"
        return 0
    end

    ## City or postal code: geocode then forecast
    set -l location_escaped (string escape --style url "$raw")
    set -l geo_url "https://geocoding-api.open-meteo.com/v1/search?name=$location_escaped&count=1"
    set -l geo_data (curl -s -A "$tide_report_user_agent" --max-time $timeout_sec "$geo_url")
    if test $status -ne 0; or test -z "$geo_data"
        echo (string trim -- "Location not found or geocoding failed.") >&2
        return 1
    end
    set -l lat (printf "%s" "$geo_data" | jq -r '.results[0].latitude // empty')
    set -l lon (printf "%s" "$geo_data" | jq -r '.results[0].longitude // empty')
    set -l name (printf "%s" "$geo_data" | jq -r '.results[0].name // empty')
    set -l admin1 (printf "%s" "$geo_data" | jq -r '.results[0].admin1 // empty')
    set -l country (printf "%s" "$geo_data" | jq -r '.results[0].country // empty')
    if test -z "$lat"; or test -z "$lon"
        echo (string trim -- "Location not found.") >&2
        return 1
    end
    set -l tz (printf "%s" "$geo_data" | jq -r '.results[0].timezone // "auto"')
    set -l tz_escaped (string escape --style url "$tz")
    set -l forecast_url "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m&timezone=$tz_escaped"
    set -l forecast_data (curl -s -A "$tide_report_user_agent" --max-time $timeout_sec "$forecast_url")
    if test $status -ne 0; or test -z "$forecast_data"
        echo (string trim -- "Weather unavailable for this location.") >&2
        return 1
    end
    if not printf "%s" "$forecast_data" | jq -e '.current.temperature_2m != null' 2>/dev/null >/dev/null
        echo (string trim -- "Weather unavailable for this location.") >&2
        return 1
    end
    set -l parts $name
    test -n "$admin1" && set parts $parts $admin1
    set parts $parts $country
    printf "%s\n" (string join ", " $parts)
    return 0
end
