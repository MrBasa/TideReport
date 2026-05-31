source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_cache_helpers.fish"

set -l tmp (mktemp -d)
set -l cache "$tmp/cache.json"

@test "cache_state stale window triggers fetch and keeps cache valid" (
    echo '{"temp_c":12}' > "$cache"
    __tide_report_test_set_cache_age "$cache" 500
    set -l now (command date +%s)
    set -l state (__tide_report_cache_state "$cache" "$now" 300 900)
    test "$state[1]" = true; and test "$state[2]" = true; and test "$state[3]" = true
    echo $status
) -eq 0

@test "cache_state missing file triggers fetch only" (
    command rm -f "$cache"
    set -l now (command date +%s)
    set -l state (__tide_report_cache_state "$cache" "$now" 300 900)
    test "$state[1]" = true; and test "$state[2]" = false
    echo $status
) -eq 0

@test "cache_state expired file triggers fetch and invalid cache" (
    echo '{"temp_c":12}' > "$cache"
    __tide_report_test_set_cache_age "$cache" 1000
    set -l now (command date +%s)
    set -l state (__tide_report_cache_state "$cache" "$now" 300 900)
    test "$state[1]" = true; and test "$state[2]" = false
    echo $status
) -eq 0

command rm -rf "$tmp"
