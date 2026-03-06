## Integration tests: install/load validation.
## Catches syntax errors and load failures in install functions (e.g. truncated code, missing end).

function _install_test_run --argument-names test_name
    set -l root (pwd)
    set -l runner $root/test/support/install_runner.fish
    set -l home (mktemp -d)
    mkdir -p $home/.config/fish
    env HOME=$home XDG_CONFIG_HOME=$home/.config fish $runner $test_name $root >/dev/null 2>&1
    set -l st $status
    command rm -rf $home
    return $st
end

@test "all function files pass fish syntax check" (
    set -l root (pwd)
    set -l failed
    for f in $root/functions/*.fish $root/conf.d/*.fish
        fish -n $f 2>/dev/null; or set failed $failed $f
    end
    if set -q failed[1]
        echo "Syntax errors in: $failed" >&2
        echo 0
    else
        echo 1
    end
) -ge 1

@test "install loads and runs (non-interactive, items already present)" (
    _install_test_run "load"; and echo 1; or echo 0
) -ge 1

@test "install adds default items when none present" (
    _install_test_run "default_items"; and echo 1; or echo 0
) -ge 1
