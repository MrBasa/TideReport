## Integration: prompt items return before slow background fetches complete.
## RUN_SLOW_TESTS=1: weather, github, tide, moon-wttr (lock-held + missing cache).
## Moon local fast test always runs (offline provider is intentionally synchronous).

source (dirname (dirname (status filename)))/helpers/setup.fish

function __tide_report_test_reset_github_context --description "Clear session GitHub context between tests"
    set -e __tide_report_github_context_repo_root 2>/dev/null
    set -e __tide_report_github_context_values 2>/dev/null
    set -e __tide_report_github_auth_ok 2>/dev/null
end

set -l local_tmp (mktemp -d)
set -g HOME "$local_tmp/home"
mkdir -p "$HOME/.cache/tide-report"
set -g tide_report_moon_provider local
command rm -f "$HOME/.cache/tide-report/moon.json"
set -l moon_local_t0 (command date +%s)
__tide_report_test_reset_print_capture
_tide_item_moon
set -l moon_local_elapsed (math (command date +%s) - $moon_local_t0)

@test "prompt moon local returns immediately with missing cache" (
    test $moon_local_elapsed -le 1
    and set -q _tide_print_item_calls
    and test (count $_tide_print_item_calls) -ge 1
    echo $status
) -eq 0

command rm -rf "$local_tmp"

if test "$RUN_SLOW_TESTS" = 1
    set -l fakebin "$REPO_ROOT/test/helpers/fake_bin"
    set -g PATH "$fakebin" $PATH
    set -l tmp (mktemp -d)
    set -g HOME "$tmp/home"
    mkdir -p "$HOME/.cache/tide-report"
    set -g TIDE_REPORT_TEST 1

    # --- weather ---
    set -l weather_cache "$HOME/.cache/tide-report/weather.json"
    set -g tide_report_weather_provider openmeteo
    set -gx TIDE_REPORT_RESOLVED_LOCATION "52.0,13.0"
    set -gx TIDE_REPORT_TEST_CURL_SLEEP_SECONDS 3
    set -gx TIDE_REPORT_TEST_CURL_FORECAST_RESPONSE "$REPO_ROOT/test/fixtures/weather/openmeteo_forecast.json"
    set -gx TIDE_REPORT_TEST_CURL_FORECAST_STATUS 0

    @test "prompt weather returns before slow fetch completes" (
        command rm -f "$weather_cache"
        command rm -rf "$HOME/.cache/tide-report/locks"
        __tide_report_test_reset_print_capture
        _tide_item_weather
        set -l lock_held 0
        test -d "$HOME/.cache/tide-report/locks/weather.lock"; and set lock_held 1
        set -l cache_missing 0
        test ! -f "$weather_cache"; and set cache_missing 1
        set -l printed 0
        set -q _tide_print_item_calls; and test (count $_tide_print_item_calls) -ge 1; and set printed 1
        command rm -rf "$HOME/.cache/tide-report/locks"
        test $lock_held -eq 1; and test $cache_missing -eq 1; and test $printed -eq 1
        echo $status
    ) -eq 0

    set -e TIDE_REPORT_RESOLVED_LOCATION
    set -e TIDE_REPORT_TEST_CURL_FORECAST_RESPONSE
    set -e TIDE_REPORT_TEST_CURL_FORECAST_STATUS

    # --- github ---
    set -l repo_tmp "$tmp/repo-slow"
    mkdir -p "$repo_tmp"
    __tide_report_test_reset_github_context
    set -g tide_report_github_show_ci false
    set -g tide_report_github_refresh_seconds 0
    set -gx TIDE_REPORT_TEST_GH_SLEEP_SECONDS 3
    set -gx TIDE_REPORT_TEST_GH_RESPONSE "$REPO_ROOT/test/fixtures/github/repo.json"
    set -gx TIDE_REPORT_TEST_GH_STATUS 0

    @test "prompt github returns before slow fetch completes" (
        command rm -rf "$HOME/.cache/tide-report/github" "$HOME/.cache/tide-report/locks"
        mkdir -p "$HOME/.cache/tide-report/github"
        pushd "$repo_tmp" >/dev/null
        command git init >/dev/null 2>&1
        command git remote add origin "https://github.com/MrBasa/TideReport.git"
        __tide_report_test_reset_github_context
        __tide_report_test_reset_print_capture
        _tide_item_github
        popd >/dev/null
        set -l lock_held 0
        test -d "$HOME/.cache/tide-report/locks/github_MrBasa_TideReport.lock"; and set lock_held 1
        set -l cache_missing 0
        test ! -f "$HOME/.cache/tide-report/github/MrBasa-TideReport.json"; and set cache_missing 1
        set -l printed 0
        set -q _tide_print_item_calls; and test (count $_tide_print_item_calls) -ge 1; and set printed 1
        command rm -rf "$HOME/.cache/tide-report/locks"
        test $lock_held -eq 1; and test $cache_missing -eq 1; and test $printed -eq 1
        echo $status
    ) -eq 0

    set -e TIDE_REPORT_TEST_GH_SLEEP_SECONDS
    set -e TIDE_REPORT_TEST_GH_RESPONSE
    set -e TIDE_REPORT_TEST_GH_STATUS

    # --- tide ---
    set -l tide_cache "$HOME/.cache/tide-report/tide.json"
    set -g tide_report_tide_station_id 8443970
    set -g tide_report_tide_refresh_seconds 0
    set -g tide_report_tide_expire_seconds 900
    set -gx TIDE_REPORT_TEST_CURL_SLEEP_SECONDS 3
    set -gx TIDE_REPORT_TEST_CURL_RESPONSE "$REPO_ROOT/test/fixtures/tide/predictions.json"
    set -gx TIDE_REPORT_TEST_CURL_STATUS 0

    @test "prompt tide returns before slow fetch completes" (
        command rm -f "$tide_cache"
        command rm -rf "$HOME/.cache/tide-report/locks"
        __tide_report_test_reset_print_capture
        _tide_item_tide
        set -l lock_held 0
        test -d "$HOME/.cache/tide-report/locks/tide.lock"; and set lock_held 1
        set -l cache_missing 0
        test ! -f "$tide_cache"; and set cache_missing 1
        set -l printed 0
        set -q _tide_print_item_calls; and test (count $_tide_print_item_calls) -ge 1; and set printed 1
        command rm -rf "$HOME/.cache/tide-report/locks"
        test $lock_held -eq 1; and test $cache_missing -eq 1; and test $printed -eq 1
        echo $status
    ) -eq 0

    set -e TIDE_REPORT_TEST_CURL_RESPONSE
    set -e TIDE_REPORT_TEST_CURL_STATUS

    # --- moon wttr ---
    set -l moon_cache "$HOME/.cache/tide-report/moon.json"
    set -g tide_report_moon_provider wttr
    set -g tide_report_weather_provider openmeteo
    set -g tide_report_moon_refresh_seconds 0
    set -g tide_report_moon_expire_seconds 900
    set -gx TIDE_REPORT_TEST_CURL_SLEEP_SECONDS 3
    set -gx TIDE_REPORT_TEST_CURL_RESPONSE "$REPO_ROOT/test/fixtures/weather/wttr.json"
    set -gx TIDE_REPORT_TEST_CURL_STATUS 0

    @test "prompt moon wttr returns before slow fetch completes" (
        command rm -f "$moon_cache"
        command rm -rf "$HOME/.cache/tide-report/locks"
        __tide_report_test_reset_print_capture
        _tide_item_moon
        set -l lock_held 0
        test -d "$HOME/.cache/tide-report/locks/moon.lock"; and set lock_held 1
        set -l cache_missing 0
        test ! -f "$moon_cache"; and set cache_missing 1
        set -l printed 0
        set -q _tide_print_item_calls; and test (count $_tide_print_item_calls) -ge 1; and set printed 1
        command rm -rf "$HOME/.cache/tide-report/locks"
        test $lock_held -eq 1; and test $cache_missing -eq 1; and test $printed -eq 1
        echo $status
    ) -eq 0

    set -e TIDE_REPORT_TEST_CURL_SLEEP_SECONDS
    set -e TIDE_REPORT_TEST_CURL_RESPONSE
    set -e TIDE_REPORT_TEST_CURL_STATUS
    set -e TIDE_REPORT_TEST
    command rm -rf "$tmp"
end
