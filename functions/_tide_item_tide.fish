## TideReport :: Tide Prompt Item
## This function handles all logic for displaying the tide prediction module.

function _tide_item_tide --description "Fetches and displays next high or low tide"
    if not set -q tide_report_tide_station_id
        set -l output (set_color $tide_report_tide_unavailable_color)"$tide_report_tide_unavailable_text!stationID"
        _tide_print_item tide $output
        return
    end

    if not functions -q _tide_report_handle_async_tide
        source (status filename | path dirname)/_tide_report_handle_async_tide.fish
    end
    if not functions -q __tide_report_gnu_date_cmd
        source (status filename | path dirname)/_tide_report_time_helpers.fish
    end

    set -l now (command date +%s)
    set -l current_date (command date +%Y%m%d)
    set -l gnu_date_cmd (__tide_report_gnu_date_cmd)
    set -l timeout_sec (math --scale=0 "$tide_report_service_timeout_millis / 1000")
    set -l cache_file ~/.cache/tide-report/tide.json
    set -l url "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?product=predictions&interval=hilo&datum=MLLW&time_zone=gmt&units=metric&format=json"
    set url "$url&station=$tide_report_tide_station_id"
    set url "$url&begin_date=$current_date"
    set url "$url&range=48"

    set -l output (_tide_report_handle_async_tide \
        "$cache_file" "$now" $tide_report_tide_refresh_seconds $tide_report_tide_expire_seconds \
        "$gnu_date_cmd" "$tide_report_tide_unavailable_text" "$tide_report_tide_unavailable_color" "!data" \
        "$timeout_sec" "$url")

    _tide_print_item tide $output
end
