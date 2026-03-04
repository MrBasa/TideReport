## Integration tests: _tide_report_uninstall removes all TideReport artifacts.
## Runs uninstall in an isolated fish process (temp HOME/config) so user universals are not touched.

function _uninstall_test_run --argument-names test_name
    set -l root (pwd)
    set -l runner $root/test/integration/uninstall_runner.fish
    set -l home (mktemp -d)
    mkdir -p $home/.config/fish
    env HOME=$home XDG_CONFIG_HOME=$home/.config fish $runner $test_name $root >/dev/null
    set -l st $status
    command rm -rf $home
    return $st
end

@test "uninstall removes TideReport prompt items and preserves others" (
    _uninstall_test_run "prompt_items"; and echo 1; or echo 0
) -ge 1

@test "uninstall erases TideReport universal variables" (
    _uninstall_test_run "universals"; and echo 1; or echo 0
) -ge 1

@test "uninstall removes cache directory" (
    _uninstall_test_run "cache"; and echo 1; or echo 0
) -ge 1

@test "uninstall erases TideReport functions" (
    _uninstall_test_run "functions"; and echo 1; or echo 0
) -ge 1
