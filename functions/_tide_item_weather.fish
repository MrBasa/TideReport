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
        __tide_report_parse_weather "$cache_file"
    end
end

# --- Parser Function ---
function __tide_report_parse_weather --argument-names cache_file
    # Set default format if user variable isn't set
    set -l format_string $tide_report_weather_format
    if test -z "$format_string"
        set format_string "%t %c"
    end

    # Get unit-specific fields
    set -l temp_field "temp_C"
    set -l feels_like_field "FeelsLikeC" # ADDED
    set -l wind_field "windspeedKmph"
    set -l wind_unit "km/h"
    # Use universal units variable
    if test "$tide_report_units" = "u" # USCS
        set temp_field "temp_F"
        set feels_like_field "FeelsLikeF" # ADDED
        set wind_field "windspeedMiles"
        set wind_unit "mph"
    end

    # Read all data from JSON cache in one `jq` call
    set -l jq_query "[
        .current_condition[0].$temp_field,
        .current_condition[0].$feels_like_field,
        .current_condition[0].weatherDesc[0].value,
        .current_condition[0].weatherCode,
        .current_condition[0].$wind_field,
        .current_condition[0].winddir16Point,
        .current_condition[0].humidity
    ] | @tsv"

    # Use `read` to assign vars, suppressing errors if cache is mid-write
    jq -r "$jq_query" "$cache_file" 2>/dev/null | read -l temp feels_like cond_text code wind wind_dir humidity
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
    set -l cond_emoji (__tide_report_get_weather_emoji "$code")

    # %w: Wind (e.g., 15mph)
    set -l wind_val (math "floor($wind + 0.5)")
    set -l wind_str "$wind_val$wind_unit"

    # %h: Humidity (e.g., 80%)
    set -l humidity_str "$humidity%"

    # %f: "Feels Like" Temperature (e.g., +8°)
    set -l feels_like_val (math "floor($feels_like + 0.5)")
    set -l feels_like_str (printf "%+d°" $feels_like_val)

    # %d: Wind Direction Arrow (e.g., ⬆)
    set -l wind_arrow_symbol (__tide_report_get_wind_arrow "$wind_dir")
    set -l wind_arrow (set_color $tide_report_weather_symbol_color)$wind_arrow_symbol(set_color $tide_weather_color)

    # Build the final output string
    set -l output $format_string
    set output (string replace -a '%t' $temp_str -- $output)
    set output (string replace -a '%C' $cond_text -- $output)
    set output (string replace -a '%c' $cond_emoji -- $output)
    set output (string replace -a '%w' $wind_str -- $output)
    set output (string replace -a '%h' $humidity_str -- $output)
    set output (string replace -a '%f' $feels_like_str -- $output)
    set output (string replace -a '%d' $wind_arrow -- $output)

    _tide_print_item weather $output
end

# --- Map wttr.in weatherCode to emoji ---
function __tide_report_get_weather_emoji --argument-names code
    switch "$code"
        case 113; echo "☀️"; # Sunny / Clear
        case 116; echo "🌤️"; # Partly cloudy
        case 119; echo "☁️"; # Cloudy
        case 122; echo "🌥️"; # Overcast
        case 143 248 260; echo "🌫️"; # Mist / Fog
        case 176 179 182 185 263 266 281 284 293 296 299 302 311 314 353 356; echo "🌦️"; # Rain / Drizzle / Sleet
        case 305 308 317 320 359 362 365 374 377; echo "🌧️"; # Heavy Rain / Sleet
        case 182 227 323 326 329 332 335 338 350 368 371 392 395; echo "🌨️"; # Snow
        case 200 386 389; echo "🌩️"; # Thunder
        case '*'; echo "❔"; # Default
    end
end

# --- Helper to map wttr.in wind direction to an arrow ---
function __tide_report_get_wind_arrow --argument-names direction
    switch "$direction"
        case "N"; echo "⬆"
        case "NNE" "NE"; echo "⬈"
        case "ENE" "E"; echo "➡"
        case "ESE" "SE"; echo "⬊"
        case "SSE" "S"; echo "⬇"
        case "SSW" "SW"; echo "⬋"
        case "WSW" "W"; echo "⬅"
        case "WNW" "NW"; echo "⬉"
        case "NNW"; echo "⬉"
        case "*"; echo "" # Default
    end
end
