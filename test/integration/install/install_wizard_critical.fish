## Critical install behavior: defaults and prompt-item insertion paths.

source (dirname (dirname (status filename)))/../helpers/setup.fish

function _install_test_run --argument-names test_name
    set -l root $REPO_ROOT
    set -l runner $root/test/support/install_runner.fish
    set -l home (mktemp -d)
    mkdir -p $home/.config/fish
    env HOME=$home XDG_CONFIG_HOME=$home/.config fish $runner $test_name $root >/dev/null 2>&1
    set -l st $status
    command rm -rf $home
    return $st
end

@test "critical install path keeps existing prompt items when already present" (
    _install_test_run load
    echo $status
) -eq 0

@test "critical install path adds default github/weather/moon items" (
    _install_test_run default_items
    echo $status
) -eq 0
