source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_item_weather.fish"

set -g tide_report_weather_format "%c %t %f %C %d %w %h %u %S %s"
set -l out (__tide_report_render_weather "+22°" "+20°" "☀️" "Clear" "12km/h" "⬇" "65%" "2" "06:00" "18:00" | string collect)

@test "render_weather fills all documented specifiers" (
    string match -q '*☀️*+22°*+20°*Clear*⬇*12km/h*65%*2*06:00*18:00*' "$out"
    echo $status
) -eq 0
