# TideReport :: Moon Prompt Item
#
# Owns moon data and moon.json cache. Dispatches by tide_report_moon_provider (local | wttr).
# When moon=wttr and weather=wttr, one request fills both. Handler in _tide_report_handle_async_moon.fish.
if not functions -q _tide_report_handle_async_moon
    source (status filename | path dirname)/_tide_report_handle_async_moon.fish
end

function _tide_item_moon --description "Displays moon phase, fetches asynchronously from JSON"
    set -l item_name "moon"
    set -l cache_file "$HOME/.cache/tide-report/moon.json"
    set -l refresh_seconds $tide_report_moon_refresh_seconds
    set -l expire_seconds $tide_report_moon_expire_seconds
    set -l unavailable_text $tide_report_moon_unavailable_text
    set -l unavailable_color $tide_report_moon_unavailable_color
    set -l timeout_sec (math --scale=0 "$tide_report_service_timeout_millis / 1000")

    if _tide_report_handle_async_moon \
        $item_name \
        $cache_file \
        $refresh_seconds \
        $expire_seconds \
        $unavailable_text \
        $unavailable_color \
        $timeout_sec

        __tide_report_parse_moon "$cache_file"
    end
end

# --- Parser Function (reads normalized moon.json) ---
function __tide_report_parse_moon --argument-names cache_file
    set -l moon_phase_text (jq -r '.phase // ""' "$cache_file" 2>/dev/null)

    if test $status -ne 0; or test -z "$moon_phase_text"
        _tide_print_item moon (set_color $tide_report_moon_unavailable_color)$tide_report_moon_unavailable_text
        return
    end

    set -l moon_emoji (__tide_report_get_moon_emoji "$moon_phase_text")
    _tide_print_item moon $moon_emoji
end

# --- Map moon phase text to emoji ---
function __tide_report_get_moon_emoji --argument-names phase_text
    switch "$phase_text"
        case "New Moon"; echo "🌑"
        case "Waxing Crescent"; echo "🌒"
        case "First Quarter"; echo "🌓"
        case "Waxing Gibbous"; echo "🌔"
        case "Full Moon"; echo "🌕"
        case "Waning Gibbous"; echo "🌖"
        case "Last Quarter"; echo "🌗"
        case "Waning Crescent"; echo "🌘"
        case "*"; echo "❔"
    end
end
