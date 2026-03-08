#!/usr/bin/env fish
## Run TideReport test suite in an isolated config so set -U in tests
## does not touch your real Fish universals (e.g. tide_left_prompt_items).
## Used by the VS Code "Test" task. Run from repo root.

set -l tmp (command mktemp -d)
set -lx HOME "$tmp"
set -lx XDG_CONFIG_HOME "$tmp/.config"
mkdir -p "$XDG_CONFIG_HOME"

set -lx RUN_NETWORK_TESTS "1"
fish -c "
    fishtape test/unit/*.fish test/unit/*/*.fish test/integration/*.fish test/integration/*/*.fish
    and fishtape test/network/*.fish
    set -l code \$status
    echo ''
    if test \$code -eq 0
        echo '--- Testing completed: all passed ---'
    else
        echo '--- Testing completed: FAILED (exit code '\$code') ---'
    end
    exit \$code
"
set -l code $status
command rm -rf "$tmp"
exit $code
