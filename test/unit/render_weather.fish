## Unit tests for __tide_report_render_weather (fixed inputs → output).

source (dirname (dirname (status filename)))/setup.fish
set -g tide_report_weather_format "%c %t %d%w"

set -l out (__tide_report_render_weather "+22°" "+21°" "☀️" "Clear" "12km/h" "⬇" "65%" "" "" "" | string collect)
set -l plain (string replace -r '\e\[[0-9;]*m' '' -- "$out")

@test "render_weather medium: non-empty output" -n "$out"
@test "render_weather medium: contains temp" (string match -q '*+22°*' $plain; and echo 0; or echo 1) -eq 0
@test "render_weather medium: contains emoji" (string match -q '*☀️*' $plain; and echo 0; or echo 1) -eq 0
@test "render_weather medium: contains wind" (string match -q '*12km/h*' $plain; and echo 0; or echo 1) -eq 0
@test "render_weather medium: contains wind arrow" (string match -q '*⬇*' $plain; and echo 0; or echo 1) -eq 0

set -g tide_report_weather_format "%c %t"
set -l out_concise (__tide_report_render_weather "+15°" "" "🌤️" "" "" "" "" "" "" "" | string collect)
set -l plain_concise (string replace -r '\e\[[0-9;]*m' '' -- "$out_concise")
@test "render_weather concise: contains temp and emoji" (string match -q '*+15°*' $plain_concise; and string match -q '*🌤️*' $plain_concise; and echo 0; or echo 1) -eq 0
