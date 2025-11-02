# TideReport :: Moon Prompt Item
#
# This function handles all logic for displaying the moon phase module.

function _tide_item_moon --description "Displays moon phase, fetches asynchronously from JSON"
    set -l item_name "moon"
    set -l cache_file "$HOME/.cache/tide-report/wttr.json" # --- SHARED CACHE ---
    set -l refresh_seconds $tide_report_moon_refresh_seconds
    set -l expire_seconds $tide_report_moon_expire_seconds
    set -l unavailable_text $tide_report_moon_unavailable_text
    set -l unavailable_color $tide_report_moon_unavailable_color
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
        __tide_report_parse_moon "$cache_file"
    end
end

# --- Internal Parser Function ---
function __tide_report_parse_moon --argument-names cache_file
    # Read the moon_phase text directly from the JSON cache
    # This field is language-independent (always English) per wttr.in JSON format.
    set -l moon_phase_text (jq -r '.weather[0].astronomy[0].moon_phase' "$cache_file" 2>/dev/null)

    if test $status -ne 0; or test -z "$moon_phase_text"
        # Fallback if jq fails (e.g., empty file)
        _tide_print_item moon (set_color $tide_report_moon_unavailable_color)$tide_report_moon_unavailable_text
        return
    end

    # BUGFIX: Translate text to emoji
    set -l moon_emoji (_tide_report_get_moon_emoji "$moon_phase_text")
    _tide_print_item moon $moon_emoji
end

# BUGFIX: Added this helper function to map the English text to an emoji
# Helper to map wttr.in moon phase text to an emoji
function _tide_report_get_moon_emoji --argument-names phase_text
    switch "$phase_text"
        case "New Moon"; echo "🌑"
        case "Waxing Crescent"; echo "🌒"
        case "First Quarter"; echo "🌓"
        case "Waxing Gibbous"; echo "🌔"
        case "Full Moon"; echo "🌕"
        case "Waning Gibbous"; echo "🌖"
        case "Last Quarter"; echo "🌗"
        case "Waning Crescent"; echo "🌘"
        case "*"; echo "❔" # Default
    end
end
