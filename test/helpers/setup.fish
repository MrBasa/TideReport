## Shared TideReport test setup.

set -g REPO_ROOT (pwd)
source "$REPO_ROOT/functions/_tide_report_defaults.fish"

function _tide_print_item --description "Capture prompt item output for assertions"
    set -q _tide_print_item_calls; or set -g _tide_print_item_calls
    set -g _tide_print_item_calls $_tide_print_item_calls (string join " " $argv)
    set -g _tide_print_item_last_argv $argv
end

function __tide_report_test_reset_print_capture --description "Clear captured prompt output"
    set -e _tide_print_item_calls
    set -e _tide_print_item_last_argv
end

function __tide_report_test_source_items --description "Source common item and async functions"
    set -l root $REPO_ROOT/functions
    source "$root/_tide_report_handle_async_weather.fish"
    source "$root/_tide_report_handle_async_moon.fish"
    source "$root/_tide_item_weather.fish"
    source "$root/_tide_item_moon.fish"
    source "$root/_tide_item_github.fish"
    source "$root/_tide_item_tide.fish"
end

__tide_report_set_if_missing g tide_report_log_expected 1
__tide_report_apply_defaults g white normal

set -q _tide_report_version; or set -g _tide_report_version "test"
set -q tide_report_user_agent; or set -g tide_report_user_agent "tide-report/test"

__tide_report_init_moon_constants g

# Preserve compatibility with existing tests that assume setup preloads item functions.
__tide_report_test_source_items

# Provide a no-op stub for _tide_report_warn_global_prompt_items in tests when the real
# implementation from conf.d/tide_report.fish has not been sourced. This prevents
# \"Unknown command\" errors (stderr noise) when install helpers call it.
functions -q _tide_report_warn_global_prompt_items; or function _tide_report_warn_global_prompt_items --argument-names left_list right_list
end
