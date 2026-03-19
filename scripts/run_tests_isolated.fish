#!/usr/bin/env fish
## Run TideReport tests in an isolated Fish config so any set -U inside
## tests does not modify your real universals (e.g. tide_left_prompt_items).
## Resolve the user's installed fishtape function once, then run tests in a
## temporary Fish config so any set -U inside tests does not modify your real
## universals (e.g. tide_left_prompt_items).
## Used by the VS Code "Test" task and the pre-push hook. Run from repo root.

set -l host_home $HOME
set -l fishtape_path "$host_home/.config/fish/functions/fishtape.fish"
if not test -f "$fishtape_path"
    echo "run_tests_isolated.fish: fishtape is not installed at $fishtape_path" >&2
    echo "Install it once with: fisher install jorgebucaran/fishtape" >&2
    exit 1
end

set -l tmp (command mktemp -d)
set -lx HOME "$tmp/home"
set -lx XDG_CONFIG_HOME "$tmp/.config"
set -lx XDG_DATA_HOME "$tmp/.local/share"
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"

set -q RUN_NETWORK_TESTS; or set -lx RUN_NETWORK_TESTS 0
set -l tap_output "$tmp/test.tap"
fish --no-config -c "source \"$fishtape_path\"
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
" | tee "$tap_output"
set -l code $pipestatus[1]
if rg -q '^not ok ' "$tap_output"
    set code 1
end
command rm -rf "$tmp"
exit $code
