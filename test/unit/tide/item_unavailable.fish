source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_item_tide.fish"

set -l tmp (mktemp -d)
set -g HOME "$tmp/home"
mkdir -p "$HOME/.cache/tide-report"
set -g tide_report_tide_unavailable_text "TUNAV"

@test "tide item appends !stationID when station unset" (
    set -e tide_report_tide_station_id 2>/dev/null
    __tide_report_test_reset_print_capture
    _tide_item_tide
    string match -q '*!stationID*' "$_tide_print_item_last_argv[2]"
    echo $status
) -eq 0

@test "tide item appends !data when parse fails on corrupt cache" (
    set -g tide_report_tide_station_id 8443970
    set -g tide_report_tide_refresh_seconds 99999
    set -g tide_report_tide_expire_seconds 99999
    printf '%s\n' '{"predictions":[]}' > "$HOME/.cache/tide-report/tide.json"
    __tide_report_test_reset_print_capture
    _tide_item_tide
    string match -q '*!data*' "$_tide_print_item_last_argv[2]"
    echo $status
) -eq 0

command rm -rf "$tmp"
