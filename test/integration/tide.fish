## Integration test: tide item with fixture cache and temp HOME.

source (dirname (dirname (status filename)))/setup.fish

set -g _test_home (mktemp -d)
set -g _saved_home $HOME
set -g HOME $_test_home
mkdir -p $HOME/.cache/tide-report
cp "$REPO_ROOT/test/fixtures/tide.json" $HOME/.cache/tide-report/tide.json

set -g tide_report_tide_station_id "8443970"
set -g tide_report_tide_refresh_seconds 99999
set -g tide_report_tide_expire_seconds 99999

_tide_item_tide

set -g HOME $_saved_home
command rm -rf $_test_home

@test "tide item called _tide_print_item" (count _tide_print_item_calls) -eq 1
@test "tide output contains tide symbol or time" (
    string match -q "*⇞*" $_tide_print_item_calls[1]; or string match -q "*⇟*" $_tide_print_item_calls[1]; or string match -q -r "[0-9]{1,2}:[0-9]{2}" $_tide_print_item_calls[1]
    echo $status
) -eq 0
@test "tide output contains time or unavailable" (
    string match -q -r "[0-9]{1,2}:[0-9]{2}|🌊" $_tide_print_item_calls[1]
    echo $status
) -eq 0
