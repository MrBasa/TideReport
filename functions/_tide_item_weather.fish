# TideReport :: Weather Prompt Item
#
# This is the main function that Tide calls to display the weather.

function _tide_item_weather --description "Displays weather, fetches asynchronously from JSON"
    set -l item_name "weather"
    set -l cache_file "$HOME/.cache/tide-report/wttr.json"
    set -l refresh_seconds $tide_report_weather_refresh_seconds
    set -l expire_seconds $tide_report_weather_expire_seconds
    set -l unavailable_text $tide_report_weather_unavailable_text
    set -l unavailable_color $tide_report_weather_unavailable_color
    set -l timeout_sec (math --scale=0 "$tide_report_service_timeout_millis / 1000")

    # Call the shared async JSON handler
    # It returns 0 if cache is valid, 1 if not (and prints unavailable text)
    if _tide_report_handle_async_wttr \
        $item_name \
        $cache_file \
        $refresh_seconds \
        $expire_seconds \
        $unavailable_text \
        $unavailable_color \
        $timeout_sec

        # Cache is valid, parse and print
        _tide_report_parse_weather "$cache_file"
    end
end

# --- Internal Parser Function ---
function _tide_report_parse_weather --argument-names cache_file
    # Set default format if user variable isn't set
    set -l format_string $tide_report_weather_format
    if test -z "$format_string"
        set format_string "%t %C"
    end

    # Get unit-specific fields
    set -l temp_field "temp_C"
    set -l wind_field "windspeedKmph"
    set -l wind_unit "km/h"
    # Use universal units variable
    if test "$tide_report_units" = "u" # USCS
        set temp_field "temp_F"
        set wind_field "windspeedMiles"
        set wind_unit "mph"
    end

    # Read all data from JSON cache in one `jq` call
    set -l jq_query "[
        .current_condition[0].$temp_field,
        .current_condition[0].weatherDesc[0].value,
        .current_condition[0].weatherIconUrl[0].value,
        .current_condition[0].$wind_field,
        .current_condition[0].humidity
    ] | @tsv"

    # Use `read` to assign vars, suppressing errors if cache is mid-write
    jq -r "$jq_query" "$cache_file" 2>/dev/null | read -l temp cond_text icon_url wind humidity
    if test $status -ne 0; or test -z "$temp"
        # Fallback if jq fails (e.g., empty file)
        _tide_print_item weather (set_color $tide_report_weather_unavailable_color)$tide_report_weather_unavailable_text
        return
    end

    # --- Format String Replacements ---

    # %t: Temperature (e.g., +10°)
    set -l temp_val (math "floor($temp + 0.5)")
    set -l temp_str (printf "%+d°" $temp_val)

    # %C: Condition Text (e.g., Clear)
    set cond_text (string replace -a '\t' ' ' -- $cond_text | string replace -ra ' {2,}' ' ')

    # %c: Condition Emoji (e.g., ☀️)
    set -l cond_emoji (_tide_report_get_weather_emoji "$icon_url")

    # %w: Wind (e.g., 15mph)
    set -l wind_val (math "floor($wind + 0.5)")
    set -l wind_str "$wind_val$wind_unit"

    # %h: Humidity (e.g., 80%)
    set -l humidity_str "$humidity%"

    # Build the final output string
    set -l output $format_string
    set output (string replace -a '%t' $temp_str -- $output)
    set output (string replace -a '%C' $cond_text -- $output)
    set output (string replace -a '%c' $cond_emoji -- $output)
    set output (string replace -a '%w' $wind_str -- $output)
    set output (string replace -a '%h' $humidity_str -- $output)

    _tide_print_item weather $output
end

# Helper to map wttr.in icon URLs to a single emoji
function _tide_report_get_weather_emoji --argument-names icon_url
    if string match -q -r "wsymbol_0001" -- $icon_url; echo "☀️"; # Sunny
    else if string match -q -r "wsymbol_0002" -- $icon_url; echo "🌤️"; # Partly cloudy
    else if string match -q -r "wsymbol_0003" -- $icon_url; echo "☁️"; # Cloudy
    else if string match -q -r "wsymbol_0004" -- $icon_url; echo "🌥️"; # Very cloudy
    else if string match -q -r "wsymbol_0006" -- $icon_url; echo "🌫️"; # Fog
    else if string match -q -r "(wsymbol_0009|wsymbol_0021)" -- $icon_url; echo "🌦️"; # Light rain
    else if string match -q -r "(wsymbol_0010|wsymbol_0024)" -- $icon_url; echo "🌧️"; # Heavy rain
    else if string match -q -r "(wsymbol_0011|wsymbol_0012|wsymbol_0022)" -- $icon_url; echo "🌨️"; # Snow
    else if string match -q -r "wsymbol_0016" -- $icon_url; echo "🌩️"; # Thundershower
    else if string match -q -r "wsymbol_0017" -- $icon_url; echo "🌦️"; # Light rain shower
    else if string match -q -r "(wsymbol_0018|wsymbol_0034)" -- $icon_url; echo "🌨️"; # Sleet
    else if string match -q -r "wsymbol_0008" -- $icon_url; echo "🌩️"; # Thunder
    else if string match -q -r "wsymbol_0007" -- $icon_url; echo "🌨️"; # Light snow
    else echo "❔"; # Default
    end
end
