# TideReport :: Weather Prompt Item
#
# This is the main function that Tide calls to display the weather.

function _tide_item_weather --description "Displays weather, fetches asynchronously from JSON"
    set -l item_name "weather"
    set -l cache_file "$HOME/.cache/tide-report/weather.json"
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

# --- Parser Function (reads normalized weather.json) ---
function __tide_report_parse_weather --argument-names cache_file
    set -l temp_field "temp_c"
    set -l feels_like_field "feels_like_c"
    set -l wind_field "wind_speed_kmh"
    set -l wind_unit "km/h"
    if test "$tide_report_units" = "u" # USCS
        set temp_field "temp_f"
        set feels_like_field "feels_like_f"
        set wind_field "wind_speed_mph"
        set wind_unit "mph"
    end

    set -l jq_query "[.$temp_field, .$feels_like_field, .condition_text, .condition_code, .$wind_field, .wind_dir_16, .humidity, .uv_index, .sunrise_utc, .sunset_utc] | join(\";\")"
    jq -r "$jq_query" "$cache_file" 2>/dev/null | read -l -d \; temp feels_like cond_text code wind wind_dir humidity uv_index sunrise_utc sunset_utc

    if test -z "$temp"
        _tide_print_item weather (set_color $tide_report_weather_unavailable_color)$tide_report_weather_unavailable_text
        return
    end

    # --- Format String Replacements ---
    set -l temp_val (math "floor($temp + 0.5)")
    set -l temp_str (printf "%+d°" $temp_val)
    set cond_text (string replace -a '\t' ' ' -- $cond_text | string replace -ra ' {2,}' ' ')
    set -l cond_emoji (__tide_report_get_weather_emoji "$code")
    set -l wind_val (math "floor($wind + 0.5)")
    set -l wind_str "$wind_val$wind_unit"
    set -l humidity_str "$humidity%"
    set -l feels_like_val (math "floor($feels_like + 0.5)")
    set -l feels_like_str (printf "%+d°" $feels_like_val)
    set -l wind_arrow (__tide_report_get_wind_arrow "$wind_dir")
    set -l uv_str $uv_index
    set -l sunrise_str (__tide_report_format_unix_time "$sunrise_utc" $tide_time_format)
    set -l sunset_str (__tide_report_format_unix_time "$sunset_utc" $tide_time_format)

    # --- Build the final output string ---
    set -l output $tide_report_weather_format
    set -l pairs '%t' $temp_str '%C' $cond_text '%c' $cond_emoji '%w' $wind_str '%h' $humidity_str '%f' $feels_like_str '%d' $wind_arrow '%u' $uv_str '%S' $sunrise_str '%s' $sunset_str
    set -l n (count $pairs)
    for i in (seq 1 2 $n)
        set output (string replace -a -- $pairs[$i] $pairs[$i+1] $output)
    end

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
    # for sym in $colorable_symbols
    #     set output (string replace -a -- $sym "$symbol_color$sym$text_color" $output)
    # end
    set -l pattern (string join '|' -- $colorable_symbols)
    set output (string replace -a -r "($pattern)" "$symbol_color\$1$text_color" "$output")

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

# --- Map wttr.in wind direction to an arrow (direction wind is blowing TO) ---
# wttr.in gives wind FROM (meteorological); we show arrow where wind is blowing TO,
# to match wttr.in's one-line format (e.g. format=2) and most weather UIs.
function __tide_report_get_wind_arrow --argument-names direction
    switch "$direction"
        case "N"; echo "⬇"   # from N → to S
        case "NNE" "NE"; echo "⬋"   # from NE → to SW
        case "ENE" "E"; echo "⬅"   # from E → to W
        case "ESE" "SE"; echo "⬉"   # from SE → to NW
        case "SSE" "S"; echo "⬆"   # from S → to N
        case "SSW" "SW"; echo "⬈"   # from SW → to NE
        case "WSW" "W"; echo "➡"   # from W → to E
        case "WNW" "NW" "NNW"; echo "⬊"   # from NW/NNW → to SE
        case "*"; echo "" # Default
    end
end

# --- Parse "07:30 AM" (today local) to Unix timestamp ---
function __tide_report_time_string_to_unix --argument-names time_str
    if test -z "$time_str"
        echo ""
        return
    end
    set -l gnu_date_cmd (__tide_report_gnu_date_cmd)
    set -l clean_time (string trim -- $time_str)
    if test -n "$gnu_date_cmd"
        $gnu_date_cmd -d "today $clean_time" +%s 2>/dev/null
    else
        set -l today (command date +%Y-%m-%d)
        command date -j -f "%Y-%m-%d %I:%M %p" "$today $clean_time" +%s 2>/dev/null
    end
end

# --- Return GNU date command name (gdate or date) or empty for BSD ---
function __tide_report_gnu_date_cmd
    if command -q gdate
        echo gdate
    else if command date --version >/dev/null ^/dev/null
        echo date
    end
end

# --- Format Unix timestamp for display ---
function __tide_report_format_unix_time --argument-names epoch_str time_format
    if test -z "$epoch_str"; or test "$epoch_str" = "null"
        echo ""
        return
    end
    set -l gnu_date_cmd (__tide_report_gnu_date_cmd)
    set -l formatted_time
    if test -n "$gnu_date_cmd"
        set formatted_time ($gnu_date_cmd -d @$epoch_str +$time_format 2>/dev/null)
    else
        set formatted_time (command date -r $epoch_str +$time_format 2>/dev/null)
    end
    if test -n "$formatted_time"
        echo "$formatted_time"
    else
        echo ""
    end
end

# --- Re-format wttr.in time strings (legacy; used only if needed) ---
function __tide_report_format_wttr_time --argument-names time_str time_format
    if test -z "$time_str"
        echo ""
        return
    end

    set -l gnu_date_cmd (__tide_report_gnu_date_cmd)

    # Strip leading/trailing whitespace
    set -l clean_time (string trim -- $time_str)
    set -l epoch_time

    # Parse time string to epoch
    if test -n "$gnu_date_cmd"
        # GNU date
        set epoch_time ($gnu_date_cmd -d "$clean_time" +%s 2>/dev/null)
    else
        # BSD date
        set epoch_time (command date -j -f "%I:%M %p" "$clean_time" +%s 2>/dev/null)
    end

    if test $status -ne 0; or test -z "$epoch_time"
        echo "$clean_time" # Fallback: return original string on error
        return
    end

    # Re-format epoch to desired format
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
