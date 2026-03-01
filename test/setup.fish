# TideReport test setup: REPO_ROOT, stub _tide_print_item, source plugin, set parser universals.
# Source this from integration tests (and optionally unit tests that need full plugin).

set -g REPO_ROOT (dirname (dirname (status filename)))

# Stub Tide's output so we can assert without Tide installed.
function _tide_print_item
    set -q _tide_print_item_calls || set -g _tide_print_item_calls
    set -g _tide_print_item_calls $_tide_print_item_calls (string join " " $argv)
end

# Source plugin functions (order: shared helper then items that use it).
set -l root $REPO_ROOT/functions
source "$root/_tide_report_handle_async_wttr.fish"
source "$root/_tide_item_weather.fish"
source "$root/_tide_item_moon.fish"
source "$root/_tide_item_github.fish"
source "$root/_tide_item_tide.fish"

# Parser universals (process-local defaults so tests don't rely on user universals).
set -q tide_report_service_timeout_millis || set -g tide_report_service_timeout_millis 6000
set -q tide_report_weather_provider      || set -g tide_report_weather_provider "wttr"
set -q tide_report_units                  || set -g tide_report_units "m"
set -q tide_time_format                   || set -g tide_time_format "%H:%M"
set -q tide_weather_color                 || set -g tide_weather_color white
set -q tide_report_weather_symbol_color   || set -g tide_report_weather_symbol_color white
set -q tide_report_weather_format         || set -g tide_report_weather_format "%c %t %d%w"
set -q tide_report_weather_refresh_seconds    || set -g tide_report_weather_refresh_seconds 900
set -q tide_report_weather_expire_seconds     || set -g tide_report_weather_expire_seconds 600
set -q tide_report_weather_unavailable_text   || set -g tide_report_weather_unavailable_text "..."
set -q tide_report_weather_unavailable_color  || set -g tide_report_weather_unavailable_color red
set -q tide_report_moon_refresh_seconds   || set -g tide_report_moon_refresh_seconds 14400
set -q tide_report_moon_expire_seconds    || set -g tide_report_moon_expire_seconds 28800
set -q tide_report_moon_unavailable_text  || set -g tide_report_moon_unavailable_text "..."
set -q tide_report_moon_unavailable_color || set -g tide_report_moon_unavailable_color red
set -q tide_report_tide_station_id        || set -g tide_report_tide_station_id "8443970"
set -q tide_report_tide_refresh_seconds   || set -g tide_report_tide_refresh_seconds 14400
set -q tide_report_tide_expire_seconds    || set -g tide_report_tide_expire_seconds 28800
set -q tide_report_tide_symbol_high       || set -g tide_report_tide_symbol_high "⇞"
set -q tide_report_tide_symbol_low        || set -g tide_report_tide_symbol_low "⇟"
set -q tide_report_tide_symbol_color      || set -g tide_report_tide_symbol_color white
set -q tide_report_tide_unavailable_text  || set -g tide_report_tide_unavailable_text "🌊..."
set -q tide_report_tide_unavailable_color || set -g tide_report_tide_unavailable_color red
set -q tide_report_tide_show_level        || set -g tide_report_tide_show_level "true"
set -q tide_report_github_icon            || set -g tide_report_github_icon ""
set -q tide_report_github_icon_stars      || set -g tide_report_github_icon_stars "★"
set -q tide_report_github_icon_forks      || set -g tide_report_github_icon_forks "⑂"
set -q tide_report_github_icon_watchers   || set -g tide_report_github_icon_watchers ""
set -q tide_report_github_icon_issues     || set -g tide_report_github_icon_issues "!"
set -q tide_report_github_icon_prs        || set -g tide_report_github_icon_prs "PR"
set -q tide_report_github_color_stars     || set -g tide_report_github_color_stars yellow
set -q tide_report_github_color_forks     || set -g tide_report_github_color_forks yellow
set -q tide_report_github_color_watchers  || set -g tide_report_github_color_watchers yellow
set -q tide_report_github_color_issues    || set -g tide_report_github_color_issues yellow
set -q tide_report_github_color_prs      || set -g tide_report_github_color_prs yellow
set -q tide_report_github_unavailable_text  || set -g tide_report_github_unavailable_text "..."
set -q tide_report_github_unavailable_color || set -g tide_report_github_unavailable_color red
set -q tide_report_github_refresh_seconds || set -g tide_report_github_refresh_seconds 30
