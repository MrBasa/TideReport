## TideReport :: Weather Prompt Item
##
## This is the main function that Tide calls to display the weather.

if not functions -q __tide_report_format_unix_time
    source (status filename | path dirname)/_tide_report_time_helpers.fish
end

function _tide_item_weather --description "Displays weather, fetches asynchronously from JSON"
    set -l item_name "weather"
    set -l cache_file "$HOME/.cache/tide-report/weather.json"
    set -l refresh_seconds $tide_report_weather_refresh_seconds
    set -l expire_seconds $tide_report_weather_expire_seconds
    set -l unavailable_text $tide_report_weather_unavailable_text
    set -l unavailable_color $tide_report_weather_unavailable_color
    set -l timeout_sec (math --scale=0 "$tide_report_service_timeout_millis / 1000")

    # 0 if cache is valid, 1 if not
    if _tide_report_handle_async_weather \
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

## --- Render: display inputs → formatted string (no I/O). Uses tide_report_weather_format and symbol color from globals. ---
function __tide_report_render_weather --description "Render weather segment from format placeholder values" --argument-names temp_str feels_like_str cond_emoji cond_text wind_str wind_arrow humidity_str uv_str sunrise_str sunset_str
    set -q temp_str || set temp_str ""
    set -q feels_like_str || set feels_like_str ""
    set -q cond_emoji || set cond_emoji ""
    set -q cond_text || set cond_text ""
    set -q wind_str || set wind_str ""
    set -q wind_arrow || set wind_arrow ""
    set -q humidity_str || set humidity_str ""
    set -q uv_str || set uv_str ""
    set -q sunrise_str || set sunrise_str ""
    set -q sunset_str || set sunset_str ""

    ## --- Build the final output string ---
    # Normalize to a single string so replacements always run on one value (handles format set as multiple elements).
    set -l output (string join ' ' $tide_report_weather_format)
    set -l pairs '%t' $temp_str '%C' $cond_text '%c' $cond_emoji '%w' $wind_str '%h' $humidity_str '%f' $feels_like_str '%d' $wind_arrow '%u' $uv_str '%S' $sunrise_str '%s' $sunset_str
    set -l n (count $pairs)
    for i in (seq 1 2 $n)
        set -l j (math $i + 1)
        set output (string replace -a -- $pairs[$i] $pairs[$j] $output)
    end

    __tide_report_weather_render_init
    set -l symbol_color $__tide_report_weather_symbol_color_code
    set -l text_color $__tide_report_weather_text_color_code
    set output (string replace -a -r "($__tide_report_weather_symbol_pattern)" "$symbol_color\$1$text_color" "$output")
    echo "$output"
end

function __tide_report_weather_render_init --description "Cache weather render helpers for the session"
    if not set -q __tide_report_weather_symbol_pattern
        set -l colorable_symbols \
             󰖚 󰖛 󰖜  \
            ⬆ ⬈ ➡ ⬊ ⬇ ⬋ ⬅ ⬉ \
            ↑ ↓ → ← ▴ ▾     \
                 🌡 󰔅 󰔄 \
             󰖌  󱂙 󱪀 󱔂 󱔃 󱔄 󱔅 󱠆 󱪆 󱔉 \
            🕶 󰓠    󰖙  󰖨 \
               󱪈 󱪉 󰖝 󱗺 \
             
        set -g __tide_report_weather_symbol_pattern (string join '|' -- $colorable_symbols)
    end

    if not set -q __tide_report_cached_weather_symbol_color_name; or test "$__tide_report_cached_weather_symbol_color_name" != "$tide_report_weather_symbol_color"
        set -g __tide_report_cached_weather_symbol_color_name "$tide_report_weather_symbol_color"
        set -g __tide_report_weather_symbol_color_code (set_color $tide_report_weather_symbol_color)
    end

    if not set -q __tide_report_cached_weather_text_color_name; or test "$__tide_report_cached_weather_text_color_name" != "$tide_weather_color"
        set -g __tide_report_cached_weather_text_color_name "$tide_weather_color"
        set -g __tide_report_weather_text_color_code (set_color $tide_weather_color)
    end
end

## --- Parser Function (reads normalized weather.json) ---
function __tide_report_parse_weather --description "Parse normalized weather.json and build formatted prompt string" --argument-names cache_file
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

    ## --- Format String Replacements ---
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

    set -l out (__tide_report_render_weather "$temp_str" "$feels_like_str" "$cond_emoji" "$cond_text" "$wind_str" "$wind_arrow" "$humidity_str" "$uv_str" "$sunrise_str" "$sunset_str")
    _tide_print_item weather "$out"
end

## --- Map wttr.in weatherCode to emoji ---
function __tide_report_get_weather_emoji --description "Map wttr.in weatherCode to a weather emoji" --argument-names code
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

## --- Map wttr.in wind direction to an arrow (direction wind is blowing TO) ---
# wttr.in gives wind FROM (meteorological); we show arrow where wind is blowing TO,
# to match wttr.in's one-line format (e.g. format=2) and most weather UIs.
function __tide_report_get_wind_arrow --description "Convert wttr.in wind direction string to an arrow glyph" --argument-names direction
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
