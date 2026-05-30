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

set -g __wizard_called 0
function _tide_report_run_wizard
    set -g __wizard_called 1
end

function _tide_report_do_install --argument-names context
    read -l -P "" wizard_reply
    if test "$context" = update
        set -l r (string trim (string lower -- "$wizard_reply"))
        if test -n "$r"; and test "$r" != "n"; and test "$r" != "no"
            if test "$r" = "y"; or test "$r" = "yes"
                _tide_report_run_wizard
            end
        end
    end
end

printf '\n' | _tide_report_do_install update

@test "update with empty wizard reply does not run wizard" $__wizard_called -eq 0

command rm -rf "$tmp"
