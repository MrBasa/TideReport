## Critical install behavior: defaults and prompt-item insertion paths.

source (dirname (dirname (status filename)))/../helpers/setup.fish

function _install_test_run --argument-names test_name
    set -l root $REPO_ROOT
    set -l runner $root/test/support/install_runner.fish
    set -l home (mktemp -d)
    mkdir -p $home/.config/fish
    env HOME=$home XDG_CONFIG_HOME=$home/.config fish $runner $test_name $root >/dev/null 2>&1
    set -l st $status
    command rm -rf $home
    return $st
end

function _install_wizard_run --argument-names test_name responses
    set -l root $REPO_ROOT
    set -l runner $root/test/support/install_runner.fish
    set -l home (mktemp -d)
    mkdir -p $home/.config/fish
    printf '%s' "$responses" | env HOME=$home XDG_CONFIG_HOME=$home/.config TERM=dumb fish --no-config -i $runner $test_name $root >/dev/null 2>&1
    set -l st $status
    command rm -rf $home
    return $st
end

@test "critical install path keeps existing prompt items when already present" (
    _install_test_run load
    echo $status
) -eq 0

@test "critical install path adds default github/weather/moon items" (
    _install_test_run default_items
    echo $status
) -eq 0

@test "install wizard explains IP-based weather auto-detect" (
    set -gx TIDE_REPORT_TEST_CURL_IP_RESPONSE '{"lat":47.61,"lon":-122.33,"city":"Seattle","regionName":"Washington","country":"United States"}'
    set -l responses (string join \n "" "" "n" "" "" "" "n" "n")
    _install_wizard_run wizard_ip_auto "$responses"
    set -e TIDE_REPORT_TEST_CURL_IP_RESPONSE
    echo $status
) -eq 0

@test "install wizard can pin weather to a fixed location" (
    set -gx TIDE_REPORT_TEST_CURL_IP_RESPONSE '{"lat":47.61,"lon":-122.33,"city":"Seattle","regionName":"Washington","country":"United States"}'
    set -gx TIDE_REPORT_TEST_CURL_GEOCODE_RESPONSE '{"results":[{"latitude":47.61,"longitude":-122.33,"name":"Seattle","admin1":"Washington","country":"United States","timezone":"America/Los_Angeles"}]}'
    set -gx TIDE_REPORT_TEST_CURL_FORECAST_RESPONSE '{"current":{"temperature_2m":11}}'
    set -l responses (string join \n "" "" "n" "" "" "n" "Seattle" "" "n" "n")
    _install_wizard_run wizard_fixed_location "$responses"
    set -e TIDE_REPORT_TEST_CURL_IP_RESPONSE
    set -e TIDE_REPORT_TEST_CURL_GEOCODE_RESPONSE
    set -e TIDE_REPORT_TEST_CURL_FORECAST_RESPONSE
    echo $status
) -eq 0

@test "install wizard falls back to IP auto-detect after repeated invalid fixed locations" (
    set -gx TIDE_REPORT_TEST_CURL_IP_RESPONSE '{"lat":47.61,"lon":-122.33,"city":"Seattle","regionName":"Washington","country":"United States"}'
    set -gx TIDE_REPORT_TEST_CURL_GEOCODE_RESPONSE '{"results":[]}'
    set -l responses (string join \n "" "" "n" "" "" "n" "Atlantis" "Atlantis" "Atlantis" "n" "n")
    _install_wizard_run wizard_ip_fallback "$responses"
    set -e TIDE_REPORT_TEST_CURL_IP_RESPONSE
    set -e TIDE_REPORT_TEST_CURL_GEOCODE_RESPONSE
    echo $status
) -eq 0
