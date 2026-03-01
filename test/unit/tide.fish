# Unit tests for tide parser (with fixture; uses real date so fixture uses future dates).

set -l root (dirname (dirname (dirname (status filename))))/functions
set -l fixtures (dirname (dirname (status filename)))/fixtures
function _tide_print_item
end
source "$root/_tide_item_weather.fish"
source "$root/_tide_item_tide.fish"

set -g tide_time_format "%H:%M"
set -g tide_report_tide_symbol_high "⇞"
set -g tide_report_tide_symbol_low "⇟"
set -q tide_report_tide_symbol_color || set -g tide_report_tide_symbol_color white
set -q tide_tide_color || set -g tide_tide_color 0087AF
set -q tide_report_tide_show_level || set -g tide_report_tide_show_level "true"

set -l now (command date +%s)
set -l gnu_date_cmd (__tide_report_gnu_date_cmd)
set -l out (__tide_report_parse_tide $now "$fixtures/tide.json" "$gnu_date_cmd")

@test "parse_tide with fixture returns non-empty output" -n "$out"
@test "parse_tide output contains tide symbol or time" (
    string match -q "*⇞*" "$out"; or string match -q "*⇟*" "$out"; or string match -q -r "[0-9]{1,2}:[0-9]{2}" "$out"
    echo $status
) -eq 0
@test "parse_tide output contains time-like pattern" (
    string match -q -r "[0-9]{1,2}:[0-9]{2}" "$out"
    echo $status
) -eq 0
