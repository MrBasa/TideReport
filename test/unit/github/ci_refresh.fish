source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_lock_helpers.fish"
source "$REPO_ROOT/functions/_tide_item_github.fish"

set -l tmp (mktemp -d)
set -l home "$tmp/home"
mkdir -p "$home/.cache/tide-report/locks"

@test "ci_effective_refresh defaults running interval to 5 seconds" (
    set -e tide_report_github_ci_running_refresh_seconds 2>/dev/null
    set -l out (__tide_report_github_ci_effective_refresh pending "" | string collect)
    echo "$out"
) = 5

@test "ci_effective_refresh uses running interval when cached state is pending" (
    set -g tide_report_github_ci_refresh_seconds 60
    set -g tide_report_github_ci_running_refresh_seconds 15
    set -l out (__tide_report_github_ci_effective_refresh pending "" | string collect)
    echo "$out"
) = 15

@test "ci_effective_refresh uses running interval when CI lock is held" (
    set -lx HOME "$home"
    set -g tide_report_github_ci_refresh_seconds 60
    set -g tide_report_github_ci_running_refresh_seconds 15
    mkdir -p "$home/.cache/tide-report/locks/github_ci_repo_main.lock"
    set -l out (__tide_report_github_ci_effective_refresh pass github_ci_repo_main | string collect)
    echo "$out"
) = 15

@test "ci_effective_refresh uses steady interval for pass without lock" (
    set -lx HOME "$home"
    set -g tide_report_github_ci_refresh_seconds 60
    set -g tide_report_github_ci_running_refresh_seconds 15
    set -l out (__tide_report_github_ci_effective_refresh pass "" | string collect)
    echo "$out"
) = 60

@test "parse_github shows pending while CI fetch is in flight over stale pass" (
    set -l cache "$tmp/repo.json"
    set -l ci "$tmp/ci.json"
    cp "$REPO_ROOT/test/fixtures/github/repo.json" "$cache"
    printf '%s\n' pass > "$ci.state"
    set -g tide_report_github_show_ci true
    set -g tide_report_github_icon_ci_pending "⏳"
    set -g TIDE_REPORT_TEST 1
    __tide_report_test_reset_print_capture
    __tide_report_parse_github "$cache" "" "$ci" true
    string match -q '*⏳*' "$_tide_print_item_last_argv[2]"
    string match -q '*✔*' "$_tide_print_item_last_argv[2]"; and echo 1; or echo 0
) -eq 0

set -e TIDE_REPORT_TEST
command rm -rf "$tmp"
