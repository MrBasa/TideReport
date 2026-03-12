#!/usr/bin/env fish
## Run TideReport tests in an isolated Fish config so any set -U inside
## tests does not modify your real universals (e.g. tide_left_prompt_items).
## Resolve the user's installed fishtape function once, then run tests in a
## temporary Fish config so any set -U inside tests does not modify your real
## universals (e.g. tide_left_prompt_items).
## Used by the VS Code "Test" task and the pre-push hook. Run from repo root.

set -l fishtape_path
if functions -q fishtape
    # functions -D fishtape prints e.g. \"# Defined in /path/to/fishtape.fish @ line 1\"
    set fishtape_path (functions -D fishtape | string match -rg 'Defined in (.+) @' | head -n 1)
end
if test -z \"$fishtape_path\"
    # Fallback to the standard Fisher-installed location under the current config dir.
    set -l cfg
    if set -q XDG_CONFIG_HOME; and test -n \"$XDG_CONFIG_HOME\"
        set cfg \"$XDG_CONFIG_HOME\"
    else
        set cfg \"$HOME/.config\"
    end
    set -l candidate \"$cfg/fish/functions/fishtape.fish\"
    if test -f \"$candidate\"
        set fishtape_path \"$candidate\"
    end
end
if test -z \"$fishtape_path\"
    echo \"run_tests_isolated.fish: fishtape is not installed or could not be found\" >&2
    exit 1
end

set -l tmp (command mktemp -d)
set -lx HOME "$tmp"
set -lx XDG_CONFIG_HOME "$tmp/.config"
mkdir -p "$XDG_CONFIG_HOME"

set -lx RUN_NETWORK_TESTS 1
fish -c "source \"$fishtape_path\"
    fishtape test/unit/*.fish test/unit/*/*.fish test/integration/*.fish test/integration/*/*.fish
    and if test \"\$RUN_NETWORK_TESTS\" = \"1\"
        fishtape test/network/*.fish
    end
    set -l code \$status
    echo ''
    if test \$code -eq 0
        echo '--- Testing completed: all passed ---'
    else
        echo \"--- Testing completed: FAILED (exit code \$code) ---\"
    end
    exit \$code
"
set -l code $status
command rm -rf "$tmp"
exit $code
