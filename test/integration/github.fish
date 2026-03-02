# Integration test: GitHub parser with fixture (parser-only; no git mock).
# Tests that with cache file present, __tide_report_parse_github runs and stub receives output.

source (dirname (dirname (status filename)))/setup.fish

set -g _test_home (mktemp -d)
set -g _saved_home $HOME
set -g HOME $_test_home
mkdir -p $HOME/.cache/tide-report/github
# Use cache key format Owner-Repo as in the plugin
cp "$REPO_ROOT/test/fixtures/github.json" $HOME/.cache/tide-report/github/Owner-Repo.json

# Parser reads the file and prints via _tide_print_item
__tide_report_parse_github "$HOME/.cache/tide-report/github/Owner-Repo.json"

set -g HOME $_saved_home
command rm -rf $_test_home

@test "github parser called _tide_print_item" (count _tide_print_item_calls) -eq 1

# --- Non–git directory: item must not print git "fatal" to stderr ---
# Use /tmp so we are definitely outside the repo (avoid TMPDIR inside repo).
set -g _nongit_dir "/tmp/tide_report_nongit_"(random)
mkdir -p $_nongit_dir
set -g _nongit_stderr "$_nongit_dir/stderr"
pushd $_nongit_dir
set -e GIT_DIR 2>/dev/null
set -e GIT_WORK_TREE 2>/dev/null
# Confirm git does not see a repo here
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
