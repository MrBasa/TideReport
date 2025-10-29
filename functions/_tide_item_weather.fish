# TideReport :: Weather Prompt Item
#
# This is the main function that Tide calls to display the weather.

function _tide_item_weather --description "Displays weather, fetches asynchronously"
    set -l item_name "weather"
    set -l cache_file "$HOME/.cache/tide-report/weather.txt"
    set -l url "$tide_report_wttr_url/$tide_report_weather_location?format=$tide_report_weather_format&$tide_report_weather_units&lang=$tide_report_weather_language"
    set -l refresh_seconds $tide_report_weather_refresh_seconds
    set -l expire_seconds $tide_report_weather_expire_seconds
    set -l unavailable_text $tide_report_weather_unavailable_text
    set -l unavailable_color $tide_report_weather_unavailable_color
    set -l timeout_sec (math --scale=0 "$tide_report_service_timeout_millis / 1000")

    # Call the shared async logic handler
    _tide_report_handle_async_item \
        $item_name \
        $cache_file \
        $url \
        $refresh_seconds \
        $expire_seconds \
        "$unavailable_text" \
        $unavailable_color \
        $timeout_sec
end
