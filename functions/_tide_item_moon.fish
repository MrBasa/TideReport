# TideReport :: Moon Prompt Item
#
# This function handles all logic for displaying the moon phase module.

function _tide_item_moon --description "Displays moon phase, fetches asynchronously"
    set -l item_name "moon"
    set -l cache_file "$HOME/.cache/tide-report/moon.txt"
    set -l url "$tide_report_wttr_url/?format=$tide_report_moon_format"
    set -l refresh_seconds $tide_report_moon_refresh_seconds
    set -l expire_seconds $tide_report_moon_expire_seconds
    set -l unavailable_text $tide_report_moon_unavailable_text
    set -l unavailable_color $tide_report_moon_unavailable_color
    set -l timeout_sec (math --scale=0 "$tide_report_service_timeout_millis / 1000")

    # Call the shared async logic handler
    _tide_report_handle_async_wttr \
        $item_name \
        $cache_file \
        $url \
        $refresh_seconds \
        $expire_seconds \
        "$unavailable_text" \
        $unavailable_color \
        $timeout_sec
end
