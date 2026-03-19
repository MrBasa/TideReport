## Integration: guard the isolated runner contract against regressions.

@test "isolated runner keeps fishtape inside isolated XDG config" (
    string match -q '*set -l fishtape_path "$XDG_CONFIG_HOME/fish/functions/fishtape.fish"*' (string collect < scripts/run_tests_isolated.fish)
    echo $status
) -eq 0

@test "isolated runner uses vendored fishtape source" (
    string match -q '*set -l vendored_fishtape "$repo_root/vendor/fishtape.fish"*' (string collect < scripts/run_tests_isolated.fish)
    echo $status
) -eq 0

@test "isolated runner does not fetch fishtape from network" (
    set -l runner (string collect < scripts/run_tests_isolated.fish)
    not string match -q '*raw.githubusercontent.com*' "$runner"; and not string match -q '*curl -fsSL*' "$runner"
    echo $status
) -eq 0

@test "set -U in isolated child does not leak to parent environment" (
    set -l var_name "__tide_report_isolation_guard_"(random)
    set -e $var_name
    set -l tmp (mktemp -d)
    mkdir -p "$tmp/home" "$tmp/.config" "$tmp/.local/share" "$tmp/.local/state"
    env HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/.config" XDG_DATA_HOME="$tmp/.local/share" XDG_STATE_HOME="$tmp/.local/state" \
        fish --no-config -c "set -U $var_name child_value"
    set -l st $status
    command rm -rf "$tmp"
    test $st -eq 0; and not set -q $var_name
    echo $status
) -eq 0
