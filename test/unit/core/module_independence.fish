set -l repo_root (dirname (dirname (dirname (dirname (status filename)))))
source "$repo_root/functions/_tide_report_defaults.fish"

function _tide_print_item
end

set -g tide_report_log_expected 1
__tide_report_apply_defaults g white normal
__tide_report_init_moon_constants g

@test "tide item works without sourcing weather item" (
    set -l tmp (mktemp -d)
    set -g HOME "$tmp/home"
    mkdir -p "$HOME/.cache/tide-report"
    cp "$repo_root/test/fixtures/tide/predictions.json" "$HOME/.cache/tide-report/tide.json"
    set -g tide_report_tide_station_id 8443970
    set -g tide_report_tide_refresh_seconds 99999
    set -g tide_report_tide_expire_seconds 99999
    functions --erase _tide_item_tide __tide_report_parse_tide __tide_report_render_tide __tide_report_fetch_tide 2>/dev/null
    functions --erase __tide_report_gnu_date_cmd __tide_report_format_unix_time __tide_report_time_string_to_unix __tide_report_format_wttr_time 2>/dev/null
    source "$repo_root/functions/_tide_item_tide.fish"
    _tide_item_tide
    set -l ok $status
    command rm -rf "$tmp"
    test $ok -eq 0
    echo $status
) -eq 0

@test "wttr provider works without sourcing weather item" (
    set -l fakebin "$repo_root/test/helpers/fake_bin"
    set -g PATH "$fakebin" $PATH
    set -l tmp (mktemp -d)
    set -g HOME "$tmp/home"
    mkdir -p "$HOME/.cache/tide-report"
    set -gx TIDE_REPORT_TEST_CURL_STATUS 0
    set -gx TIDE_REPORT_TEST_CURL_RESPONSE "$repo_root/test/fixtures/weather/wttr.json"
    functions --erase __tide_report_provider_wttr __tide_report_time_string_to_unix __tide_report_gnu_date_cmd __tide_report_format_unix_time __tide_report_format_wttr_time 2>/dev/null
    source "$repo_root/functions/_tide_report_provider_weather_wttr.fish"
    __tide_report_provider_wttr "$HOME/.cache/tide-report/weather.json" 5 weather
    set -l ok $status
    set -e TIDE_REPORT_TEST_CURL_STATUS
    set -e TIDE_REPORT_TEST_CURL_RESPONSE
    command rm -rf "$tmp"
    test $ok -eq 0
    echo $status
) -eq 0
