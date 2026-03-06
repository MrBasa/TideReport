## Helper for uninstall tests: run in isolated fish with HOME and XDG_CONFIG_HOME set.
## Usage: env HOME=$tmp XDG_CONFIG_HOME=$tmp/.config fish test/support/uninstall_runner.fish $test_name $repo_root
## Exits 0 if the requested test passes, 1 otherwise.

set -l test_name $argv[1]
set -l root $argv[2]
if test -z "$test_name"; or test -z "$root"
    echo "Usage: fish test/support/uninstall_runner.fish <test_name> <repo_root>" >&2
    exit 2
end

set -U tide_left_prompt_items git github pwd
set -U tide_right_prompt_items "weather moon" time
set -U tide_report_user_agent test
set -U tide_weather_color white
set -U tide_report_weather_format "%c %t"
mkdir -p $HOME/.cache/tide-report
touch $HOME/.cache/tide-report/foo

# Add plugin functions dir so _tide_report_do_install/_tide_report_do_uninstall can be autoloaded
set -g fish_function_path $root/functions $fish_function_path

source $root/conf.d/tide_report.fish
_tide_report_uninstall

switch $test_name
    case "prompt_items"
        if contains -- github $tide_left_prompt_items; exit 1; end
        if contains -- weather $tide_right_prompt_items; exit 1; end
        if contains -- moon $tide_right_prompt_items; exit 1; end
        if contains -- "weather moon" $tide_right_prompt_items; exit 1; end
        if not contains -- git $tide_left_prompt_items; exit 1; end
        if not contains -- pwd $tide_left_prompt_items; exit 1; end
        if not contains -- time $tide_right_prompt_items; exit 1; end
    case "universals"
        if set -q tide_report_user_agent; exit 1; end
        if set -q tide_weather_color; exit 1; end
        if set -q tide_report_weather_format; exit 1; end
    case "cache"
        if test -d $HOME/.cache/tide-report; exit 1; end
    case "functions"
        if functions -q _tide_report_uninstall; exit 1; end
        if functions -q _tide_report_install; exit 1; end
        if functions -q _tide_report_apply_prompt_items; exit 1; end
    case "*"
        echo "Unknown test: $test_name" >&2
        exit 2
end
exit 0
