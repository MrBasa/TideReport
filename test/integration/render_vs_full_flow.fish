## Integration: render(precomputed inputs) vs full flow with fixture cache — same normalized output.

source (dirname (dirname (status filename)))/setup.fish
pushd "$REPO_ROOT" >/dev/null
set -g REPO_ROOT (pwd)
popd >/dev/null

function _strip_ansi --argument-names s
    string replace -r '\e\[[0-9;]*m' '' -- "$s"
end

## --- GitHub: render(42,3,10,2,1,pass) vs parse(fixture with CI) ---
set -g _gh_fixture "$REPO_ROOT/test/fixtures/github.json"
set -g _gh_jq_line (command jq -r '[.stargazerCount,.forkCount,.watchers.totalCount,.issues.totalCount,.pullRequests.totalCount]|join(" ")' "$_gh_fixture" 2>/dev/null)
set -g _ci_file "$REPO_ROOT/test/cache/github/ci_completed_success.json"
command mkdir -p (dirname $_ci_file)
echo '[{"status":"completed","conclusion":"success","name":"test"}]' > "$_ci_file"
set -g tide_report_github_show_ci true
set -g _gh_cache_path "$REPO_ROOT/test/cache/gh_home/.cache/tide-report/github/MrBasa-TideReport.json"
command mkdir -p (dirname $_gh_cache_path)
cp "$_gh_fixture" "$_gh_cache_path"
set -g _tide_print_item_calls
set -g TIDE_REPORT_TEST 1
__tide_report_parse_github "$_gh_cache_path" "$_gh_jq_line" "$_ci_file"
set -g _flow_out ""
if set -q _tide_print_item_last_argv[2]
    set _flow_out "$_tide_print_item_last_argv[2]"
end
set -l flow_plain (_strip_ansi "$_flow_out")
set -l render_out (__tide_report_render_github 42 3 10 2 1 pass | string collect)
set -l render_plain (_strip_ansi "$render_out")
set -e TIDE_REPORT_TEST 2>/dev/null

@test "github: render(42,3,10,2,1,pass) matches parse(fixture+CI) normalized" (
    string trim "$flow_plain"
) = (string trim "$render_plain")

## --- Moon: render(Full Moon) vs parse(moon fixture) ---
set -g _moon_fixture "$REPO_ROOT/test/fixtures/moon.json"
set -g _moon_cache "$REPO_ROOT/test/cache/moon_render_test.json"
command mkdir -p (dirname $_moon_cache)
cp "$_moon_fixture" "$_moon_cache"
set -g _tide_print_item_calls
__tide_report_parse_moon "$_moon_cache"
set -g _moon_flow_out ""
if set -q _tide_print_item_last_argv[2]
    set _moon_flow_out "$_tide_print_item_last_argv[2]"
end
set -l moon_flow_plain (_strip_ansi "$_moon_flow_out")
set -l moon_render (__tide_report_get_moon_emoji "Full Moon")

@test "moon: get_moon_emoji(Full Moon) matches parse(moon fixture) output" (
    string trim "$moon_flow_plain"
) = "$moon_render"

## --- Weather: full flow output contains same key tokens as render with fixture-derived inputs ---
set -g _weather_fixture "$REPO_ROOT/test/fixtures/weather.json"
set -g _weather_cache "$REPO_ROOT/test/cache/weather_render_test.json"
command mkdir -p (dirname $_weather_cache)
cp "$_weather_fixture" "$_weather_cache"
set -g _tide_print_item_calls
__tide_report_parse_weather "$_weather_cache"
set -g _weather_flow_out ""
if set -q _tide_print_item_last_argv[2]
    set _weather_flow_out "$_tide_print_item_last_argv[2]"
end
set -l weather_flow_plain (_strip_ansi "$_weather_flow_out")
set -l cond_emoji (__tide_report_get_weather_emoji "113")
set -l wind_arrow (__tide_report_get_wind_arrow "SW")
set -l weather_render_out (__tide_report_render_weather "+12°" "+10°" "$cond_emoji" "Clear" "15km/h" "$wind_arrow" "72%" "2" "" "" | string collect)
set -l weather_render_plain (_strip_ansi "$weather_render_out")

@test "weather: full flow output contains expected tokens from fixture" (
    string match -q '*+12°*' "$weather_flow_plain"; and string match -q '*☀️*' "$weather_flow_plain"; and string match -q '*15km/h*' "$weather_flow_plain"
    echo $status
) -eq 0
@test "weather: render(fixture-derived inputs) matches full flow key tokens" (
    string match -q '*+12°*' "$weather_render_plain"; and string match -q '*+12°*' "$weather_flow_plain"
    echo $status
) -eq 0

## --- Tide: full flow with fixture produces output; render with same logical shape matches structure ---
set -g _tide_fixture "$REPO_ROOT/test/fixtures/tide.json"
set -g _tide_cache "$REPO_ROOT/test/cache/tide_render_test.json"
command mkdir -p (dirname $_tide_cache)
cp "$_tide_fixture" "$_tide_cache"
set -l now (command date +%s)
set -l gnu_date_cmd (__tide_report_gnu_date_cmd)
set -l tide_flow_out (__tide_report_parse_tide $now "$_tide_cache" "$gnu_date_cmd" 2>/dev/null | string collect)
set -l tide_flow_plain (_strip_ansi "$tide_flow_out")
set -l tide_render_out (__tide_report_render_tide H "00:18" 9.398 true | string collect)
set -l tide_render_plain (_strip_ansi "$tide_render_out")

@test "tide: full flow with fixture returns non-empty output" -n "$tide_flow_out"
@test "tide: full flow output contains time-like pattern" (
    string match -q -r '[0-9]{1,2}:[0-9]{2}' "$tide_flow_plain"
    echo $status
) -eq 0
@test "tide: render output contains level in meters" (
    string match -q '*9.4*' "$tide_render_plain"; or string match -q '*9.398*' "$tide_render_plain"
    echo $status
) -eq 0
