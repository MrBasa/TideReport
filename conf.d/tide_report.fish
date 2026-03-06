## TideReport :: Default Configuration

## Plugin version (single source of truth for display and API client string)
set -g _tide_report_version "1.6"
set -q tide_report_user_agent || set -U tide_report_user_agent "tide-report/$_tide_report_version"
set -q tide_report_log_expected || set -U tide_report_log_expected 1

# Moon phase math constants (used by __tide_report_moon_* helpers, session-scoped globals)
set -q __tide_report_moon_PI           || set -g __tide_report_moon_PI (math "acos(-1)")
set -q __tide_report_moon_rad          || set -g __tide_report_moon_rad (math "$__tide_report_moon_PI / 180")
set -q __tide_report_moon_day_seconds  || set -g __tide_report_moon_day_seconds 86400
set -q __tide_report_moon_J1970        || set -g __tide_report_moon_J1970 2440588
set -q __tide_report_moon_J2000        || set -g __tide_report_moon_J2000 2451545
set -q __tide_report_moon_obliquity    || set -g __tide_report_moon_obliquity (math "$__tide_report_moon_rad * 23.4397")

## If user has prompt item lists set globally (e.g. in config.fish), inform them and show copy-paste lines.
## Arguments: left_list and right_list as space-separated strings (the lists we just wrote). Either may be empty.
function _tide_report_warn_global_prompt_items --description "Warn when a global shadows; show session fix and config.fish line" --argument-names left_list right_list
    set -q left_list || set left_list ""
    set -q right_list || set right_list ""
    set -q -g tide_left_prompt_items; or set -q -g tide_right_prompt_items; or return 0
    echo (set_color bryellow)"You have tide_left_prompt_items and/or tide_right_prompt_items set globally (e.g. in config.fish), which overrides the list we just updated."(set_color normal)
    echo (set_color brwhite)"To see the change in this session, run:"(set_color normal)
    echo (set_color cyan)"  set -e -g tide_left_prompt_items ; set -e -g tide_right_prompt_items ; tide reload"(set_color normal)
    echo (set_color brwhite)"To make it permanent, update the corresponding line(s) in your config.fish. Example:"(set_color normal)
    test -n "$left_list" && echo (set_color cyan)"  set -g tide_left_prompt_items $left_list"(set_color normal)
    test -n "$right_list" && echo (set_color cyan)"  set -g tide_right_prompt_items $right_list"(set_color normal)
end

## Install TideReport defaults and register prompt items on Fisher install event.
function _tide_report_install --description "Install TideReport defaults and prompt items on fisher event" --on-event tide_report_install
    _tide_report_do_install
end

## Handle Fisher update event: clear cache and re-run install logic.
function _tide_report_update --description "Handle fisher update: clear TideReport cache and re-run install" --on-event tide_report_update
    command rm -rf ~/.cache/tide-report
    _tide_report_do_install
end

## Uninstall TideReport: remove prompt items, variables, functions, and cache on Fisher uninstall.
function _tide_report_uninstall --description "Handle fisher uninstall: remove TideReport items, vars, functions, and cache" --on-event tide_report_uninstall
    _tide_report_do_uninstall
end
