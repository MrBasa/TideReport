## Integration test: GitHub item uses temp HOME cache and deterministic assertions.

source (dirname (dirname (status filename)))/helpers/setup.fish
__tide_report_test_source_items

set -l tmp (mktemp -d)
set -g HOME "$tmp/home"
mkdir -p "$HOME/.cache/tide-report/github"
cp "$REPO_ROOT/test/fixtures/github/repo.json" "$HOME/.cache/tide-report/github/MrBasa-TideReport.json"
set -g tide_report_github_refresh_seconds 99999
set -g tide_report_github_ci_refresh_seconds 99999
set -g tide_report_github_show_ci false
set -g TIDE_REPORT_TEST 1

set -l repo_tmp "$tmp/repo"
mkdir -p "$repo_tmp"
pushd "$repo_tmp" >/dev/null
command git init >/dev/null 2>&1
command git remote add origin "https://github.com/MrBasa/TideReport.git"
__tide_report_test_reset_print_capture
_tide_item_github
popd >/dev/null

@test "github item renders stats from cache in git repo" (
    set -l p "$_tide_print_item_last_argv[2]"
    string match -q '*★42*' "$p"; and string match -q '*⑂3*' "$p"
    echo $status
) -eq 0

@test "github item emits nothing in non-git directory" (
    set -l d "$tmp/no-git"
    mkdir -p "$d"
    pushd "$d" >/dev/null
    __tide_report_test_reset_print_capture
    _tide_item_github
    set -l c (count $_tide_print_item_calls)
    popd >/dev/null
    test $c -eq 0
    echo $status
) -eq 0

@test "github item emits nothing when origin is not on GitHub" (
    set -l other_tmp "$tmp/repo-non-github"
    mkdir -p "$other_tmp"
    pushd "$other_tmp" >/dev/null
    command git init >/dev/null 2>&1
    command git remote add origin "https://gitlab.com/group/repo.git"
    __tide_report_test_reset_print_capture
    _tide_item_github
    set -l c (count $_tide_print_item_calls)
    popd >/dev/null
    test $c -eq 0
    echo $status
) -eq 0

set -e TIDE_REPORT_TEST
command rm -rf "$tmp"
