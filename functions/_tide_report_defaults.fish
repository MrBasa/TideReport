## TideReport :: Shared defaults and constants

function __tide_report_set_if_missing --description "Set a variable only when it is missing" --argument-names scope var_name
    set -q $var_name; and return 0

    switch "$scope"
        case U
            set -U $var_name $argv[3..-1]
        case g
            set -g $var_name $argv[3..-1]
        case '*'
            return 1
    end
end

function __tide_report_init_moon_constants --description "Initialize moon math constants once" --argument-names scope
    __tide_report_set_if_missing "$scope" __tide_report_moon_PI (math --scale=max "acos(-1)")
    __tide_report_set_if_missing "$scope" __tide_report_moon_rad (math --scale=max "$__tide_report_moon_PI / 180")
    __tide_report_set_if_missing "$scope" __tide_report_moon_day_seconds 86400
    __tide_report_set_if_missing "$scope" __tide_report_moon_J1970 2440588
    __tide_report_set_if_missing "$scope" __tide_report_moon_J2000 2451545
    __tide_report_set_if_missing "$scope" __tide_report_moon_obliquity (math --scale=max "$__tide_report_moon_rad * 23.4397")
end

function __tide_report_apply_defaults --description "Apply TideReport defaults for the requested variable scope" --argument-names scope default_color default_bg_color
    __tide_report_set_if_missing "$scope" tide_report_service_timeout_millis 6000
    __tide_report_set_if_missing "$scope" tide_report_wttr_url "https://wttr.in"
    __tide_report_set_if_missing "$scope" tide_report_weather_provider "openmeteo"
    __tide_report_set_if_missing "$scope" tide_report_units "m"
    __tide_report_set_if_missing "$scope" tide_time_format "%H:%M"

    __tide_report_set_if_missing "$scope" tide_weather_color $default_color
    __tide_report_set_if_missing "$scope" tide_weather_bg_color $default_bg_color
    __tide_report_set_if_missing "$scope" tide_report_weather_symbol_color white
    __tide_report_set_if_missing "$scope" tide_report_weather_format "%c %t %d%w"
    __tide_report_set_if_missing "$scope" tide_report_weather_location ""
    __tide_report_set_if_missing "$scope" tide_report_weather_refresh_seconds 300
    __tide_report_set_if_missing "$scope" tide_report_weather_expire_seconds 900
    __tide_report_set_if_missing "$scope" tide_report_weather_language "en"
    __tide_report_set_if_missing "$scope" tide_report_weather_unavailable_text "…"
    __tide_report_set_if_missing "$scope" tide_report_weather_unavailable_color red

    __tide_report_set_if_missing "$scope" tide_moon_color $default_color
    __tide_report_set_if_missing "$scope" tide_moon_bg_color $default_bg_color
    __tide_report_set_if_missing "$scope" tide_report_moon_provider "local"
    __tide_report_set_if_missing "$scope" tide_report_moon_refresh_seconds 14400
    __tide_report_set_if_missing "$scope" tide_report_moon_expire_seconds 28800
    __tide_report_set_if_missing "$scope" tide_report_moon_unavailable_text "…"
    __tide_report_set_if_missing "$scope" tide_report_moon_unavailable_color red

    __tide_report_set_if_missing "$scope" tide_tide_color 0087AF
    __tide_report_set_if_missing "$scope" tide_tide_bg_color $default_bg_color
    __tide_report_set_if_missing "$scope" tide_report_tide_station_id "8443970"
    __tide_report_set_if_missing "$scope" tide_report_tide_refresh_seconds 14400
    __tide_report_set_if_missing "$scope" tide_report_tide_expire_seconds 28800
    __tide_report_set_if_missing "$scope" tide_report_tide_symbol_high "⇞"
    __tide_report_set_if_missing "$scope" tide_report_tide_symbol_low "⇟"
    __tide_report_set_if_missing "$scope" tide_report_tide_symbol_color white
    __tide_report_set_if_missing "$scope" tide_report_tide_unavailable_text "🌊…"
    __tide_report_set_if_missing "$scope" tide_report_tide_unavailable_color red
    __tide_report_set_if_missing "$scope" tide_report_tide_show_level "true"

    __tide_report_set_if_missing "$scope" tide_github_color white
    __tide_report_set_if_missing "$scope" tide_github_bg_color $default_bg_color
    __tide_report_set_if_missing "$scope" tide_report_github_icon ""
    __tide_report_set_if_missing "$scope" tide_report_github_icon_stars "★"
    __tide_report_set_if_missing "$scope" tide_report_github_icon_forks "⑂"
    __tide_report_set_if_missing "$scope" tide_report_github_icon_watchers ""
    __tide_report_set_if_missing "$scope" tide_report_github_icon_issues "!"
    __tide_report_set_if_missing "$scope" tide_report_github_icon_prs "PR"
    __tide_report_set_if_missing "$scope" tide_report_github_color_stars yellow
    __tide_report_set_if_missing "$scope" tide_report_github_color_forks yellow
    __tide_report_set_if_missing "$scope" tide_report_github_color_watchers yellow
    __tide_report_set_if_missing "$scope" tide_report_github_color_issues yellow
    __tide_report_set_if_missing "$scope" tide_report_github_color_prs yellow
    __tide_report_set_if_missing "$scope" tide_report_github_show_ci true
    __tide_report_set_if_missing "$scope" tide_report_github_icon_ci_pass "✔"
    __tide_report_set_if_missing "$scope" tide_report_github_icon_ci_fail "✗"
    __tide_report_set_if_missing "$scope" tide_report_github_icon_ci_pending "⋯"
    __tide_report_set_if_missing "$scope" tide_report_github_color_ci_pass green
    __tide_report_set_if_missing "$scope" tide_report_github_color_ci_fail red
    __tide_report_set_if_missing "$scope" tide_report_github_color_ci_pending yellow
    __tide_report_set_if_missing "$scope" tide_report_github_refresh_seconds 30
    __tide_report_set_if_missing "$scope" tide_report_github_ci_refresh_seconds 60
    __tide_report_set_if_missing "$scope" tide_report_github_unavailable_text "…"
    __tide_report_set_if_missing "$scope" tide_report_github_unavailable_color red
end
