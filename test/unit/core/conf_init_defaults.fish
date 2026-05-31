set -l repo_root (dirname (dirname (dirname (dirname (status filename)))))
set -l tmp (mktemp -d)
set -g HOME "$tmp/home"
set -g XDG_CONFIG_HOME "$tmp/config"
mkdir -p "$HOME" "$XDG_CONFIG_HOME"

source "$repo_root/conf.d/tide_report.fish"

@test "conf init sets plugin user-agent default" -n "$tide_report_user_agent"
@test "conf init sets log_expected default" -n "$tide_report_log_expected"
@test "conf init installs event handlers" (
    functions -q _tide_report_install; and functions -q _tide_report_update; and functions -q _tide_report_uninstall
    echo $status
) -eq 0

# Sample defaults from __tide_report_apply_defaults — values must match README tables.
set -e tide_report_service_timeout_millis
set -e tide_report_weather_provider
set -e tide_report_units
set -e tide_report_weather_refresh_seconds
set -e tide_report_weather_expire_seconds
set -e tide_report_moon_provider
set -e tide_report_github_refresh_seconds
set -e tide_report_github_ci_refresh_seconds
set -e tide_report_tide_station_id
__tide_report_apply_defaults g white normal

@test "defaults match README tide_report_service_timeout_millis" "$tide_report_service_timeout_millis" = 6000
@test "defaults match README tide_report_weather_provider" "$tide_report_weather_provider" = openmeteo
@test "defaults match README tide_report_units" "$tide_report_units" = m
@test "defaults match README tide_report_weather_refresh_seconds" "$tide_report_weather_refresh_seconds" = 300
@test "defaults match README tide_report_weather_expire_seconds" "$tide_report_weather_expire_seconds" = 900
@test "defaults match README tide_report_moon_provider" "$tide_report_moon_provider" = local
@test "defaults match README tide_report_github_refresh_seconds" "$tide_report_github_refresh_seconds" = 30
@test "defaults match README tide_report_github_ci_refresh_seconds" "$tide_report_github_ci_refresh_seconds" = 60
@test "defaults match README tide_report_tide_station_id" "$tide_report_tide_station_id" = 8443970

command rm -rf "$tmp"
