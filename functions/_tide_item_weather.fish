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

    # 0 if cache is valid, 1 if not
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
    # Get unit-specific fields
    set -l temp_field "temp_C"
    set -l feels_like_field "FeelsLikeC"
    set -l wind_field "windspeedKmph"
    set -l wind_unit "km/h"
    # Use universal units variable
    if test "$tide_report_units" = "u" # USCS
        set temp_field "temp_F"
        set feels_like_field "FeelsLikeF"
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
        .current_condition[0].humidity,
        .current_condition[0].uvIndex,
        .weather[0].astronomy[0].sunrise,
        .weather[0].astronomy[0].sunset
    ] | join(\";\")" # Use semicolon as delimiter for the read

    jq -r "$jq_query" "$cache_file" 2>/dev/null | read -l -d \; temp feels_like cond_text code wind wind_dir humidity uv_index sunrise sunset

    echo $jq_query > ~/tmp.log
    echo $temp >> ~/tmp.log

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
    set -l wind_arrow (__tide_report_get_wind_arrow "$wind_dir")
    # %u: UV Index (e.g., 2)
    set -l uv_str $uv_index
    # %S: Sunrise time (e.g., 07:24 AM)
    set -l sunrise_str (string trim -- $sunrise)
    # %s: Sunset time (e.g., 05:45 PM)
    set -l sunset_str (string trim -- $sunset)
    # %S: Sunrise time
    set -l sunrise_str (__tide_report_format_wttr_time "$sunrise" $tide_time_format)
    # %s: Sunset time
    set -l sunset_str (__tide_report_format_wttr_time "$sunset" $tide_time_format)

    # --- Build the final output string ---
    set -l output $tide_report_weather_format
    set output (string replace -a '%t' $temp_str -- $output)
    set output (string replace -a '%C' $cond_text -- $output)
    set output (string replace -a '%c' $cond_emoji -- $output)
    set output (string replace -a '%w' $wind_str -- $output)
    set output (string replace -a '%h' $humidity_str -- $output)
    set output (string replace -a '%f' $feels_like_str -- $output)
    set output (string replace -a '%d' $wind_arrow -- $output)
    set output (string replace -a '%u' $uv_str -- $output)
    set output (string replace -a '%S' $sunrise_str -- $output)
    set output (string replace -a '%s' $sunset_str -- $output)

    # Symbol coloring
    # List of single-color text symbols (Nerd Font, Unicode)
    set -l colorable_symbols \
        # Sunrise/Sunset
         󰖚 󰖛 󰖜  \
        # Wind Direction
        ⬆ ⬈ ➡ ⬊ ⬇ ⬋ ⬅ ⬉ \
        # Simple Arrows
        ↑ ↓ → ← ▴ ▾     \
        # Temperature
             🌡 󰔅 󰔄 \
        # Humidity
         󰖌  󱂙 󱪀 󱔂 󱔃 󱔄 󱔅 󱠆 󱪆 󱔉 \
        # UV
        🕶 󰓠    󰖙  󰖨 \
        # Wind
           󱪈 󱪉 󰖝 󱗺 \
        # Feel like
         

    # Apply symbol color
    set -l symbol_color (set_color $tide_report_weather_symbol_color)
    set -l text_color (set_color $tide_weather_color)
    for sym in $colorable_symbols
        set output (string replace -a -- $sym "$symbol_color$sym$text_color" $output)
    end

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

# --- Map wttr.in wind direction to an arrow ---
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

# --- Re-format wttr.in time strings ---
function __tide_report_format_wttr_time --argument-names time_str time_format
    if test -z "$time_str"
        echo ""
        return
    end

    set -l gnu_date_cmd
    if command -q gdate
        set gnu_date_cmd gdate
    else if command date --version >/dev/null 2>&1
        set gnu_date_cmd date
    end

    # Strip leading/trailing whitespace
    set -l clean_time (string trim -- $time_str)
    set -l epoch_time

    # 1. Parse time string to epoch
    if test -n "$gnu_date_cmd"
        # GNU date is easy
        set epoch_time ($gnu_date_cmd -d "$clean_time" +%s 2>/dev/null)
    else
        # BSD date needs a specific format
        set epoch_time (command date -j -f "%I:%M %p" "$clean_time" +%s 2>/dev/null)
    end

    if test $status -ne 0; or test -z "$epoch_time"
        echo "$clean_time" # Fallback: return original string on error
        return
    end

    # 2. Re-format epoch to desired format
    set -l formatted_time
    if test -n "$gnu_date_cmd"
        set formatted_time ($gnu_date_cmd -d @$epoch_time +$time_format 2>/dev/null)
    else
        set formatted_time (command date -r $epoch_time +$time_format 2>/dev/null)
    end

    if test $status -eq 0; and test -n "$formatted_time"
        echo "$formatted_time"
    else
        echo "$clean_time" # Fallback
    end
end
