#!/usr/bin/env fish
## Run TideReport tests in an isolated Fish config so any set -U inside
## tests does not modify your real universals (e.g. tide_left_prompt_items).
## Keep the user's real Fish functions path available so installed tools like
## fishtape can still autoload while HOME/XDG_CONFIG_HOME point at a temp dir.
## Used by the VS Code "Test" task and the pre-push hook. Run from repo root.

set -l original_home "$HOME"
set -l original_xdg_config_home
if set -q XDG_CONFIG_HOME; and test -n "$XDG_CONFIG_HOME"
    set original_xdg_config_home "$XDG_CONFIG_HOME"
else
    set original_xdg_config_home "$original_home/.config"
end
set -l original_functions_dir "$original_xdg_config_home/fish/functions"

set -l tmp (command mktemp -d)
set -lx HOME "$tmp"
set -lx XDG_CONFIG_HOME "$tmp/.config"
mkdir -p "$XDG_CONFIG_HOME"

set -l child_init ""
if test -d "$original_functions_dir"
    set child_init "set -g fish_function_path \"$original_functions_dir\" \$fish_function_path;"
end

set -lx RUN_NETWORK_TESTS 1
fish -c "$child_init
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
