# Integration test: GitHub item.
# 1) Full item with valid cache: must call _tide_print_item and display something.
# 2) Parser with fixture data: exact output (★42 ⑂3 ⑀10 !2 PR1).
# 3) Non-git dir: no git fatal on stderr.
# 4) Stale cache: no disown error on stderr.

source (dirname (dirname (status filename)))/setup.fish
# Ensure REPO_ROOT is absolute so paths are valid regardless of cwd
pushd "$REPO_ROOT" >/dev/null
set -g REPO_ROOT (pwd)
popd >/dev/null

# --- Full item with valid cache: must display something ---
set -g _gh_home "$REPO_ROOT/test/cache/gh_home"
set -g _gh_saved_home $HOME
set -g HOME $_gh_home
command mkdir -p "$HOME/.cache/tide-report/github"
cp "$REPO_ROOT/test/fixtures/github.json" "$HOME/.cache/tide-report/github/MrBasa-TideReport.json"
set -g tide_report_github_refresh_seconds 99999
set -g TIDE_REPORT_TEST 1
pushd "$REPO_ROOT" >/dev/null
_tide_item_github
popd >/dev/null
set -e TIDE_REPORT_TEST 2>/dev/null
set -g HOME $_gh_saved_home

set -g _github_calls (string join " " $_tide_print_item_calls)
set -g _gh_result_file "$REPO_ROOT/test/cache/gh_result.txt"
mkdir -p (dirname $_gh_result_file)
echo "$_github_calls" > $_gh_result_file

@test "github item called _tide_print_item" (count _tide_print_item_calls) -ge 1
@test "github item displays something (digit, unavailable text, or item label)" (
    set -l payload (cat $_gh_result_file 2>/dev/null)
    string match -q -r "[0-9]" "$payload"; or string match -q "*$tide_report_github_unavailable_text*" "$payload"; or string match -q "*github*" "$payload"
    echo $status
) -eq 0
@test "github output has no raw format placeholders" (
    set -l payload (cat $_gh_result_file 2>/dev/null)
    string match -q "*%t*" "$payload"; or string match -q "*%c*" "$payload"; or string match -q "*%d*" "$payload"; or string match -q "*%w*" "$payload"
    set -l bad $status
    test $bad -eq 0; and echo 1; or echo 0
) -eq 0

# --- Parser with fixture: exact output (run in main process so stub sees the call) ---
set -g _gh_cache_path "$REPO_ROOT/test/cache/gh_home/.cache/tide-report/github/MrBasa-TideReport.json"
set -g _gh_jq_line (command jq -r '[.stargazerCount,.forkCount,.watchers.totalCount,.issues.totalCount,.pullRequests.totalCount]|join(" ")' "$REPO_ROOT/test/fixtures/github.json" 2>/dev/null)
set -g _tide_print_item_calls
set -g TIDE_REPORT_TEST 1
__tide_report_parse_github "$_gh_cache_path" "$_gh_jq_line"
set -e TIDE_REPORT_TEST 2>/dev/null
# Use last argv[2] from stub so we get raw output (with set_color) not the joined string
set -g _parser_payload ""
if set -q _tide_print_item_last_argv[2]
    set _parser_payload "$_tide_print_item_last_argv[2]"
end
# Strip ANSI codes so we can match symbols/numbers regardless of set_color
set -g _parser_plain (string replace -r '\e\[[0-9;]*m' '' "$_parser_payload")
set -g _parser_result_file "$REPO_ROOT/test/cache/gh_parser_result.txt"
echo "$_parser_plain" > $_parser_result_file

@test "github parser with fixture was invoked" (count _tide_print_item_calls) -ge 1
@test "github parser output contains expected fixture values (★42, ⑂3, 10, !2, PR1)" (
    set -l p (cat $_parser_result_file 2>/dev/null)
    string match -q "*★42*" "$p"; and string match -q "*⑂3*" "$p"; and string match -q "*10*" "$p"; and string match -q "*!2*" "$p"; and string match -q "*PR1*" "$p"
    echo $status
) -eq 0

# --- Non–git directory: item must not print git "fatal" to stderr ---
set -g _nongit_dir "/tmp/tide_report_nongit_"(random)
mkdir -p $_nongit_dir
set -g _nongit_stderr "$_nongit_dir/stderr"
pushd $_nongit_dir
set -e GIT_DIR 2>/dev/null
set -e GIT_WORK_TREE 2>/dev/null
command git rev-parse --is-inside-work-tree 2>/dev/null >/dev/null
set -g _git_nongit_status $status
_tide_item_github 2>$_nongit_stderr
set -g _github_nongit_stderr (cat $_nongit_stderr 2>/dev/null)
popd
command rm -rf $_nongit_dir

@test "from non-git dir git rev-parse fails" $_git_nongit_status -ne 0
@test "github item in non-git dir produces no git fatal on stderr" (
    count (string match -r "fatal" $_github_nongit_stderr)
) -eq 0

# --- Stale cache: full item triggers fetch + disown; must not print disown error ---
set -g _saved_home_gh $HOME
set -g _gh_test_home (mktemp -d)
set -g HOME $_gh_test_home
mkdir -p $HOME/.cache/tide-report/github
set -e _tide_report_gh_lock_MrBasa_TideReport 2>/dev/null
pushd $REPO_ROOT
set -g _github_stderr "$_gh_test_home/stderr"
_tide_item_github 2>$_github_stderr
set -g _github_item_stderr (cat $_github_stderr 2>/dev/null)
popd
set -g HOME $_saved_home_gh
command rm -rf $_gh_test_home

@test "github item with stale cache does not print disown error on stderr" (
    string match -q "*no suitable jobs*" "$_github_item_stderr"; and echo 1; or echo 0
) -eq 0
