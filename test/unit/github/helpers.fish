source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_github_discover.fish"
source "$REPO_ROOT/functions/_tide_item_github.fish"

set -l tmp (mktemp -d)

@test "github_stats_line_valid accepts five numeric fields" (
    __tide_report_github_stats_line_valid "42 3 10 2 1"
    echo $status
) -eq 0

@test "github_stats_line_valid rejects short or non-numeric lines" (
    __tide_report_github_stats_line_valid "42 3 10 2"; and echo 1; or echo 0
) -eq 0

@test "github_ci_state_from_json maps completed success to pass" (
    echo '[{"status":"completed","conclusion":"success"}]' > "$tmp/ci-pass.json"
    __tide_report_github_ci_state_from_json "$tmp/ci-pass.json"
) = "pass"

@test "github_ci_state_from_json maps completed failure to fail" (
    echo '[{"status":"completed","conclusion":"failure"}]' > "$tmp/ci-fail.json"
    __tide_report_github_ci_state_from_json "$tmp/ci-fail.json"
) = "fail"

@test "github_ci_state_from_json maps in-progress runs to pending" (
    echo '[{"status":"in_progress","conclusion":null}]' > "$tmp/ci-pending.json"
    __tide_report_github_ci_state_from_json "$tmp/ci-pending.json"
) = "pending"

@test "github_ci_state_from_json returns none for empty run list" (
    echo '[]' > "$tmp/ci-empty.json"
    __tide_report_github_ci_state_from_json "$tmp/ci-empty.json"
) = "none"

@test "github_origin_from_config reads origin url" (
    mkdir -p "$tmp/git"
    printf '%s\n' \
        '[remote "origin"]' \
        '	url = https://github.com/MrBasa/TideReport.git' \
        > "$tmp/git/config"
    __tide_report_github_origin_from_config "$tmp/git"
) = "https://github.com/MrBasa/TideReport.git"

@test "github_discover_repo finds directory git from nested path" (
    mkdir -p "$tmp/repo/src" "$tmp/repo/.git/refs/heads"
    printf '%s\n' 'ref: refs/heads/main' > "$tmp/repo/.git/HEAD"
    printf '%s\n' \
        '[remote "origin"]' \
        '	url = https://github.com/MrBasa/TideReport.git' \
        > "$tmp/repo/.git/config"
    set -l found (__tide_report_github_discover_repo "$tmp/repo/src")
    test (count $found) -eq 2
    and test (path normalize "$found[1]") = (path normalize "$tmp/repo")
    echo $status
) -eq 0

@test "github_branch_from_head reads branch ref from HEAD file" (
    mkdir -p "$tmp/git/refs/heads"
    printf '%s\n' 'ref: refs/heads/feature/test' > "$tmp/git/HEAD"
    __tide_report_github_branch_from_head "$tmp/git"
) = "feature/test"

@test "github_branch_from_head returns empty for detached HEAD" (
    mkdir -p "$tmp/git-detached"
    printf '%s\n' 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef' > "$tmp/git-detached/HEAD"
    test -z (__tide_report_github_branch_from_head "$tmp/git-detached" | string collect)
    echo $status
) -eq 0

@test "github_path_within accepts repo root and nested paths" (
    __tide_report_github_path_within "/repo" "/repo"; and \
    __tide_report_github_path_within "/repo/src" "/repo"
    echo $status
) -eq 0

@test "github_path_within rejects paths outside repo root" (
    __tide_report_github_path_within "/other" "/repo"
    echo $status
) -eq 1

@test "github_ci_cache_file sanitizes branch names for filesystem paths" (
    set -l path (__tide_report_github_ci_cache_file "$tmp/cache" "Owner-Repo" "feature/bad name")
    string match -q '*feature_bad_name-ci.json' "$path"
    echo $status
) -eq 0

@test "github_ci_cache_file uses detached suffix when branch is empty" (
    set -l path (__tide_report_github_ci_cache_file "$tmp/cache" "Owner-Repo" "")
    string match -q '*Owner-Repo-detached-ci.json' "$path"
    echo $status
) -eq 0

@test "render_github omits CI icons when show_ci is false" (
    set -g tide_report_github_show_ci false
    set -g TIDE_REPORT_TEST 1
    set -l out (__tide_report_render_github 10 1 2 0 0 pass | string collect)
    set -e TIDE_REPORT_TEST
    string match -q '*✔*' "$out"; and echo 1; or echo 0
) -eq 0

command rm -rf "$tmp"
