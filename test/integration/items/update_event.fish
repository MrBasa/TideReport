## Integration: update event clears cache and invokes install flow.

set -l tmp (mktemp -d)
set -g HOME "$tmp/home"
set -g XDG_CONFIG_HOME "$tmp/config"
mkdir -p "$HOME/.cache/tide-report" "$XDG_CONFIG_HOME"
touch "$HOME/.cache/tide-report/stale"

source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/conf.d/tide_report.fish"

set -g __install_called 0
function _tide_report_do_install
    set -g __install_called 1
end

_tide_report_update

@test "update event removes cache directory" (
    test -d "$HOME/.cache/tide-report"; and echo 1; or echo 0
) -eq 0

@test "update event calls install function" $__install_called -eq 1

command rm -rf "$tmp"
