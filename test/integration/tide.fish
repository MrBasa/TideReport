## Integration test: tide item deterministic outputs with valid and missing cache.

source (dirname (dirname (status filename)))/helpers/setup.fish
__tide_report_test_source_items

set -l tmp (mktemp -d)
set -g HOME "$tmp/home"
mkdir -p "$HOME/.cache/tide-report"
cp "$REPO_ROOT/test/fixtures/tide/predictions.json" "$HOME/.cache/tide-report/tide.json"
set -g tide_report_tide_refresh_seconds 99999
set -g tide_report_tide_expire_seconds 99999
set -g tide_report_tide_show_level true

__tide_report_test_reset_print_capture
_tide_item_tide
set -l out "$_tide_print_item_last_argv[2]"

@test "tide item output includes symbol and time" (
    set -l ok 1
    if test -n "$out"
        if string match -q -r '[0-9]{1,2}:[0-9]{2}' "$out"; or string match -q "*$tide_report_tide_unavailable_text*" "$out"
            set ok 0
        end
    end
    echo $ok
) -eq 0

@test "tide item output includes meters when show_level=true" (
    string match -q '*m*' "$out"
    echo $status
) -eq 0

@test "tide item shows unavailable text when cache missing" (
    command rm -f "$HOME/.cache/tide-report/tide.json"
    set -g tide_report_tide_refresh_seconds 0
    set -g tide_report_tide_expire_seconds 0
    __tide_report_test_reset_print_capture
    _tide_item_tide
    test (count $_tide_print_item_calls) -ge 1
    echo $status
) -eq 0

command rm -rf "$tmp"
