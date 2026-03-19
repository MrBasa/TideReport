#!/usr/bin/env fish
## Run TideReport tests in an isolated Fish config so any set -U inside
## tests does not modify your real universals (e.g. tide_left_prompt_items).
## Bootstrap a vendored fishtape inside a temporary fish config/home and run
## the suite from that isolated environment only.
## Used by the VS Code "Test" task and the pre-push hook. Run from repo root.

set -l repo_root (command realpath (status dirname)/..)
set -l vendored_fishtape "$repo_root/vendor/fishtape.fish"
if not test -f "$vendored_fishtape"
    echo "run_tests_isolated.fish: vendored fishtape missing at $vendored_fishtape" >&2
    exit 1
end

set -l tmp (command mktemp -d)
set -lx HOME "$tmp/home"
set -lx XDG_CONFIG_HOME "$tmp/.config"
set -lx XDG_DATA_HOME "$tmp/.local/share"
set -lx XDG_STATE_HOME "$tmp/.local/state"
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CONFIG_HOME/fish/functions"

if not string match -q "$tmp/*" "$HOME"
    echo "run_tests_isolated.fish: isolation failed; HOME is outside temp dir: $HOME" >&2
    command rm -rf "$tmp"
    exit 1
end
if not string match -q "$tmp/*" "$XDG_CONFIG_HOME"
    echo "run_tests_isolated.fish: isolation failed; XDG_CONFIG_HOME is outside temp dir: $XDG_CONFIG_HOME" >&2
    command rm -rf "$tmp"
    exit 1
end
if not string match -q "$tmp/*" "$XDG_DATA_HOME"
    echo "run_tests_isolated.fish: isolation failed; XDG_DATA_HOME is outside temp dir: $XDG_DATA_HOME" >&2
    command rm -rf "$tmp"
    exit 1
end
if not string match -q "$tmp/*" "$XDG_STATE_HOME"
    echo "run_tests_isolated.fish: isolation failed; XDG_STATE_HOME is outside temp dir: $XDG_STATE_HOME" >&2
    command rm -rf "$tmp"
    exit 1
end

set -l fishtape_path "$XDG_CONFIG_HOME/fish/functions/fishtape.fish"
if not test -f "$fishtape_path"
    command cp "$vendored_fishtape" "$fishtape_path"
    or begin
        echo "run_tests_isolated.fish: failed to copy vendored fishtape into isolated env" >&2
        command rm -rf "$tmp"
        exit 1
    end
end
if not test -f "$fishtape_path"
    echo "run_tests_isolated.fish: fishtape was not installed at $fishtape_path" >&2
    command rm -rf "$tmp"
    exit 1
end

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
