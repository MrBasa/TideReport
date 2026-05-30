## TideReport :: Default Configuration

source (status filename | path dirname | path dirname)/functions/_tide_report_defaults.fish

## Plugin version (single source of truth for display and API client string)
set -g _tide_report_version "1.7.0"
__tide_report_set_if_missing U tide_report_user_agent "tide-report/$_tide_report_version"
__tide_report_set_if_missing U tide_report_log_expected 1

# Moon phase math constants (used by __tide_report_moon_* helpers, session-scoped globals)
__tide_report_init_moon_constants g

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
