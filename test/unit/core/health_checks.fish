source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_health_checks.fish"

set -l fakebin "$REPO_ROOT/test/helpers/fake_bin"
set -gx TIDE_REPORT_TEST_SKIP_DOCTOR_NETWORK 1

function __tide_report_test_reset_health_env --description "Reset prompt lists and health test hooks"
    set -e -U tide_left_prompt_items 2>/dev/null
    set -e -U tide_right_prompt_items 2>/dev/null
    set -e -g tide_left_prompt_items 2>/dev/null
    set -e -g tide_right_prompt_items 2>/dev/null
    set -e TIDE_REPORT_TEST_CMD_MISSING
    set -e TIDE_REPORT_TEST_VALIDATE_WEATHER_FAIL
    set -e TIDE_REPORT_TEST_GH_AUTH_FAIL
    set -e TIDE_REPORT_TEST_IP_GEO_FAIL
    set -g PATH "$fakebin" $PATH
end

__tide_report_test_reset_health_env

@test "enabled_items returns empty when prompt lists unset" (
    set -l items (_tide_report_enabled_items)
    test (count $items) -eq 0
    echo $status
) -eq 0

@test "enabled_items lists items from left and right" (
    __tide_report_test_reset_health_env
    set -U tide_left_prompt_items git github
    set -U tide_right_prompt_items weather moon
    set -l items (_tide_report_enabled_items | string collect)
    string match -q '*github*' "$items"
    and string match -q '*weather*' "$items"
    and string match -q '*moon*' "$items"
    echo $status
) -eq 0

@test "doctor with no enabled items prints info line" (
    __tide_report_test_reset_health_env
    set -l out (_tide_report_run_health_checks 2>&1 | string collect)
    string match -q '*No TideReport prompt items*' "$out"
    echo $status
) -eq 0

@test "doctor does not warn about curl when only moon local is enabled" (
    __tide_report_test_reset_health_env
    set -gx TIDE_REPORT_TEST_CMD_MISSING curl
    set -U tide_right_prompt_items moon
    set -U tide_report_moon_provider local
    set -l out (_tide_report_run_health_checks 2>&1 | string collect)
    string match -q '*curl*' "$out"; and echo 1; or echo 0
) -eq 0

@test "doctor warns about curl when weather is enabled" (
    __tide_report_test_reset_health_env
    set -gx TIDE_REPORT_TEST_CMD_MISSING curl
    set -U tide_right_prompt_items weather
    set -U tide_report_weather_provider openmeteo
    set -l out (_tide_report_run_health_checks 2>&1 | string collect)
    string match -qi '*curl*' "$out"
    echo $status
) -eq 0

@test "doctor warns on invalid openmeteo location fixture" (
    __tide_report_test_reset_health_env
    set -U tide_right_prompt_items weather
    set -U tide_report_weather_provider openmeteo
    set -U tide_report_weather_location "BadPlace"
    set -gx TIDE_REPORT_TEST_VALIDATE_WEATHER_FAIL 1
    set -l out (_tide_report_run_health_checks 2>&1 | string collect)
    string match -q '*tide_report_weather_location*' "$out"
    echo $status
) -eq 0

@test "doctor warns on moon wttr with openmeteo and empty location" (
    __tide_report_test_reset_health_env
    set -e -g tide_report_moon_provider 2>/dev/null
    set -e -U tide_report_moon_provider 2>/dev/null
    set -e -g tide_report_weather_provider 2>/dev/null
    set -e -U tide_report_weather_provider 2>/dev/null
    set -e -U tide_report_weather_location 2>/dev/null
    set -e -g tide_report_weather_location 2>/dev/null
    set -g tide_report_moon_provider wttr
    set -g tide_report_weather_provider openmeteo
    set -l out (__tide_report_health_check_moon_wttr stderr 2>&1 | string collect)
    string match -q '*tide_report_weather_location*' "$out"
    echo $status
) -eq 0

@test "doctor warns on empty tide station id" (
    __tide_report_test_reset_health_env
    set -U tide_right_prompt_items tide
    set -e -U tide_report_tide_station_id 2>/dev/null
    set -e -g tide_report_tide_station_id 2>/dev/null
    set -l out (_tide_report_run_health_checks 2>&1 | string collect)
    string match -q '*tide_report_tide_station_id*' "$out"
    echo $status
) -eq 0

@test "doctor warns on non-numeric tide station id" (
    __tide_report_test_reset_health_env
    set -U tide_right_prompt_items tide
    set -U tide_report_tide_station_id abc
    set -l out (_tide_report_run_health_checks 2>&1 | string collect)
    string match -q '*numeric*' "$out"
    echo $status
) -eq 0

@test "doctor warns on default Boston station when tide enabled" (
    __tide_report_test_reset_health_env
    set -U tide_right_prompt_items tide
    set -U tide_report_tide_station_id 8443970
    set -l out (_tide_report_run_health_checks 2>&1 | string collect)
    string match -q '*Boston*' "$out"
    echo $status
) -eq 0

@test "doctor warns on unknown weather provider" (
    __tide_report_test_reset_health_env
    set -e -g tide_report_weather_provider 2>/dev/null
    set -e -U tide_report_weather_provider 2>/dev/null
    set -g tide_report_weather_provider typo
    set -l out (__tide_report_health_check_weather_provider stderr 2>&1 | string collect)
    string match -q '*Unknown tide_report_weather_provider*' "$out"
    echo $status
) -eq 0

@test "doctor warns on unknown moon provider" (
    __tide_report_test_reset_health_env
    set -e -g tide_report_moon_provider 2>/dev/null
    set -e -U tide_report_moon_provider 2>/dev/null
    set -g tide_report_moon_provider network
    set -l out (__tide_report_health_check_moon_provider stderr 2>&1 | string collect)
    string match -q '*Unknown tide_report_moon_provider*' "$out"
    echo $status
) -eq 0

@test "doctor warns when github enabled and gh auth fails" (
    __tide_report_test_reset_health_env
    set -U tide_left_prompt_items github
    set -U tide_report_github_show_ci true
    set -gx TIDE_REPORT_TEST_GH_AUTH_FAIL 1
    set -l out (_tide_report_run_health_checks 2>&1 | string collect)
    string match -q '*authenticated*' "$out"
    and string match -q '*CI status*' "$out"
    echo $status
) -eq 0

@test "doctor quiet mode omits nerd font info" (
    __tide_report_test_reset_health_env
    set -U tide_right_prompt_items weather
    set -l out (_tide_report_run_health_checks --quiet 2>&1 | string collect)
    string match -q '*Nerd Font*' "$out"; and echo 1; or echo 0
) -eq 0

@test "doctor prints global prompt override warning" (
    __tide_report_test_reset_health_env
    set -U tide_left_prompt_items github
    set -U tide_right_prompt_items weather
    set -g tide_left_prompt_items pwd
    set -l out (_tide_report_health_prompt_list_reminders stderr 2>&1 | string collect)
    string match -q '*set globally*' "$out"
    echo $status
) -eq 0
