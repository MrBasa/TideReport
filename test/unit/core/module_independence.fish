set -l repo_root (dirname (dirname (dirname (dirname (status filename)))))
source "$repo_root/functions/_tide_report_defaults.fish"

function _tide_print_item
end

set -g tide_report_log_expected 1
__tide_report_apply_defaults g white normal
__tide_report_init_moon_constants g

source (dirname (dirname (status filename)))/../helpers/setup.fish

@test "moon handler autoload does not define weather providers" (
    functions --erase __tide_report_provider_weather_wttr __tide_report_provider_weather_openmeteo __tide_report_fetch_weather _tide_report_handle_async_moon 2>/dev/null
    source "$repo_root/functions/_tide_report_handle_async_moon.fish"
    not functions -q __tide_report_provider_weather_wttr
    and not functions -q __tide_report_provider_weather_openmeteo
    and not functions -q __tide_report_fetch_weather
    echo $status
) -eq 0

@test "moon local handler does not load weather providers" (
    set -l tmp (mktemp -d)
    set -g HOME "$tmp/home"
    mkdir -p "$HOME/.cache/tide-report"
    functions --erase __tide_report_provider_weather_wttr __tide_report_provider_weather_openmeteo __tide_report_fetch_weather __tide_report_provider_moon_local _tide_report_handle_async_moon 2>/dev/null
    set -g tide_report_moon_provider local
    source "$repo_root/functions/_tide_report_handle_async_moon.fish"
    _tide_report_handle_async_moon moon "$HOME/.cache/tide-report/moon.json" 10 20 "NA" red 5
    set -l ok $status
    set -l no_weather (not functions -q __tide_report_provider_weather_wttr; and not functions -q __tide_report_fetch_weather; and echo 0; or echo 1)
    command rm -rf "$tmp"
    test $ok -eq 1; and test $no_weather -eq 0
    echo $status
) -eq 0

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
    functions --erase __tide_report_provider_weather_wttr __tide_report_time_string_to_unix __tide_report_gnu_date_cmd __tide_report_format_unix_time __tide_report_format_wttr_time 2>/dev/null
    source "$repo_root/functions/_tide_report_provider_weather_wttr.fish"
    __tide_report_provider_weather_wttr "$HOME/.cache/tide-report/weather.json" 5 weather
    set -l ok $status
    set -e TIDE_REPORT_TEST_CURL_STATUS
    set -e TIDE_REPORT_TEST_CURL_RESPONSE
    command rm -rf "$tmp"
    test $ok -eq 0
    echo $status
) -eq 0
