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

# Seed Tide colors so install previews can render in isolated test shells.
set -g tide_time_color white
set -g tide_time_bg_color normal

# Add plugin functions dir so _tide_report_do_install can be autoloaded
set -g fish_function_path $root/functions $fish_function_path
set -g REPO_ROOT $root
source $root/test/helpers/setup.fish

source $root/conf.d/tide_report.fish

function _install_test_prepare_wizard --argument-names root
    set -l fakebin $root/test/helpers/fake_bin
    set -gx PATH "$fakebin" $PATH
    set -U tide_left_prompt_items git pwd
    set -U tide_right_prompt_items time
    set -U tide_report_weather_location "OldTown"
end

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
    case "wizard_ip_auto"
        _install_test_prepare_wizard "$root"
        emit tide_report_install
        if not contains -- weather $tide_right_prompt_items; exit 1; end
        if test -n "$tide_report_weather_location"; exit 1; end
    case "wizard_fixed_location"
        _install_test_prepare_wizard "$root"
        emit tide_report_install
        if not contains -- weather $tide_right_prompt_items; exit 1; end
        if test "$tide_report_weather_location" != "Seattle"; exit 1; end
    case "wizard_ip_fallback"
        _install_test_prepare_wizard "$root"
        emit tide_report_install
        if not contains -- weather $tide_right_prompt_items; exit 1; end
        if test -n "$tide_report_weather_location"; exit 1; end
    case "*"
        echo "Unknown test: $test_name" >&2
        exit 2
end
exit 0
