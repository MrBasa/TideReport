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
