## Shared TideReport test setup.

set -g REPO_ROOT (pwd)

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

# Process-local defaults mirroring README/conf.d defaults unless overridden by a test.
set -q tide_report_service_timeout_millis; or set -g tide_report_service_timeout_millis 6000
set -q tide_report_wttr_url; or set -g tide_report_wttr_url "https://wttr.in"
set -q tide_report_weather_provider; or set -g tide_report_weather_provider "openmeteo"
set -q tide_report_units; or set -g tide_report_units "m"
set -q tide_time_format; or set -g tide_time_format "%H:%M"
set -q tide_report_log_expected; or set -g tide_report_log_expected 1

set -q tide_weather_color; or set -g tide_weather_color white
set -q tide_weather_bg_color; or set -g tide_weather_bg_color normal
set -q tide_report_weather_symbol_color; or set -g tide_report_weather_symbol_color white
set -q tide_report_weather_format; or set -g tide_report_weather_format "%c %t %d%w"
set -q tide_report_weather_location; or set -g tide_report_weather_location ""
set -q tide_report_weather_refresh_seconds; or set -g tide_report_weather_refresh_seconds 300
set -q tide_report_weather_expire_seconds; or set -g tide_report_weather_expire_seconds 900
set -q tide_report_weather_language; or set -g tide_report_weather_language "en"
set -q tide_report_weather_unavailable_text; or set -g tide_report_weather_unavailable_text "…"
set -q tide_report_weather_unavailable_color; or set -g tide_report_weather_unavailable_color red

set -q tide_moon_color; or set -g tide_moon_color white
set -q tide_moon_bg_color; or set -g tide_moon_bg_color normal
set -q tide_report_moon_provider; or set -g tide_report_moon_provider "local"
set -q tide_report_moon_refresh_seconds; or set -g tide_report_moon_refresh_seconds 14400
set -q tide_report_moon_expire_seconds; or set -g tide_report_moon_expire_seconds 28800
set -q tide_report_moon_unavailable_text; or set -g tide_report_moon_unavailable_text "…"
set -q tide_report_moon_unavailable_color; or set -g tide_report_moon_unavailable_color red

set -q tide_tide_color; or set -g tide_tide_color 0087AF
set -q tide_tide_bg_color; or set -g tide_tide_bg_color normal
set -q tide_report_tide_station_id; or set -g tide_report_tide_station_id "8443970"
set -q tide_report_tide_refresh_seconds; or set -g tide_report_tide_refresh_seconds 14400
set -q tide_report_tide_expire_seconds; or set -g tide_report_tide_expire_seconds 28800
set -q tide_report_tide_symbol_high; or set -g tide_report_tide_symbol_high "⇞"
set -q tide_report_tide_symbol_low; or set -g tide_report_tide_symbol_low "⇟"
set -q tide_report_tide_symbol_color; or set -g tide_report_tide_symbol_color white
set -q tide_report_tide_unavailable_text; or set -g tide_report_tide_unavailable_text "🌊…"
set -q tide_report_tide_unavailable_color; or set -g tide_report_tide_unavailable_color red
set -q tide_report_tide_show_level; or set -g tide_report_tide_show_level "true"

set -q tide_github_color; or set -g tide_github_color white
set -q tide_github_bg_color; or set -g tide_github_bg_color normal
set -q tide_report_github_icon; or set -g tide_report_github_icon ""
set -q tide_report_github_icon_stars; or set -g tide_report_github_icon_stars "★"
set -q tide_report_github_icon_forks; or set -g tide_report_github_icon_forks "⑂"
set -q tide_report_github_icon_watchers; or set -g tide_report_github_icon_watchers ""
set -q tide_report_github_icon_issues; or set -g tide_report_github_icon_issues "!"
set -q tide_report_github_icon_prs; or set -g tide_report_github_icon_prs "PR"
set -q tide_report_github_color_stars; or set -g tide_report_github_color_stars yellow
set -q tide_report_github_color_forks; or set -g tide_report_github_color_forks yellow
set -q tide_report_github_color_watchers; or set -g tide_report_github_color_watchers yellow
set -q tide_report_github_color_issues; or set -g tide_report_github_color_issues yellow
set -q tide_report_github_color_prs; or set -g tide_report_github_color_prs yellow
set -q tide_report_github_show_ci; or set -g tide_report_github_show_ci true
set -q tide_report_github_icon_ci_pass; or set -g tide_report_github_icon_ci_pass "✔"
set -q tide_report_github_icon_ci_fail; or set -g tide_report_github_icon_ci_fail "✗"
set -q tide_report_github_icon_ci_pending; or set -g tide_report_github_icon_ci_pending "⋯"
set -q tide_report_github_color_ci_pass; or set -g tide_report_github_color_ci_pass green
set -q tide_report_github_color_ci_fail; or set -g tide_report_github_color_ci_fail red
set -q tide_report_github_color_ci_pending; or set -g tide_report_github_color_ci_pending yellow
set -q tide_report_github_refresh_seconds; or set -g tide_report_github_refresh_seconds 30
set -q tide_report_github_ci_refresh_seconds; or set -g tide_report_github_ci_refresh_seconds 60
set -q tide_report_github_unavailable_text; or set -g tide_report_github_unavailable_text "…"
set -q tide_report_github_unavailable_color; or set -g tide_report_github_unavailable_color red

set -q _tide_report_version; or set -g _tide_report_version "test"
set -q tide_report_user_agent; or set -g tide_report_user_agent "tide-report/test"

# Moon math constants for tests that source moon helpers directly.
set -q __tide_report_moon_PI; or set -g __tide_report_moon_PI (math "acos(-1)")
set -q __tide_report_moon_rad; or set -g __tide_report_moon_rad (math "$__tide_report_moon_PI / 180")
set -q __tide_report_moon_day_seconds; or set -g __tide_report_moon_day_seconds 86400
set -q __tide_report_moon_J1970; or set -g __tide_report_moon_J1970 2440588
set -q __tide_report_moon_J2000; or set -g __tide_report_moon_J2000 2451545
set -q __tide_report_moon_obliquity; or set -g __tide_report_moon_obliquity (math "$__tide_report_moon_rad * 23.4397")

# Preserve compatibility with existing tests that assume setup preloads item functions.
__tide_report_test_source_items
