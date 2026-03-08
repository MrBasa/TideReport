## Helper for install tests: run in isolated fish with HOME and XDG_CONFIG_HOME set.
## Usage: env HOME=$tmp XDG_CONFIG_HOME=$tmp/.config fish test/support/install_runner.fish $test_name $repo_root
## The VS Code "Test" task uses scripts/run_tests_isolated.fish so universals are not written to your shell.
## Exits 0 if the requested test passes, 1 otherwise.

set -l test_name $argv[1]
set -l root $argv[2]
if test -z "$test_name"; or test -z "$root"
    echo "Usage: fish test/support/install_runner.fish <test_name> <repo_root>" >&2
    exit 2
end

# Add plugin functions dir so _tide_report_do_install can be autoloaded
set -g fish_function_path $root/functions $fish_function_path

source $root/conf.d/tide_report.fish

switch $test_name
    case "load"
        # Non-interactive: set items so we take the "already present" path and exit quickly
        set -U tide_left_prompt_items git pwd
        set -U tide_right_prompt_items time
        # This triggers load of _tide_report_do_install and runs the install logic
        emit tide_report_install
    case "default_items"
        # Non-interactive: items set but no TideReport items -> _tide_report_ensure_prompt_items adds github, weather, moon
        set -U tide_left_prompt_items git pwd
        set -U tide_right_prompt_items time
        emit tide_report_install
        # Verify default items were added
        if not contains -- github $tide_left_prompt_items; exit 1; end
        if not contains -- weather $tide_right_prompt_items; exit 1; end
        if not contains -- moon $tide_right_prompt_items; exit 1; end
        # Verify key defaults are initialized
        if test "$tide_report_weather_provider" != "openmeteo"; exit 1; end
        if test "$tide_report_moon_provider" != "local"; exit 1; end
        if test "$tide_report_units" != "m"; exit 1; end
    case "*"
        echo "Unknown test: $test_name" >&2
        exit 2
end
exit 0
