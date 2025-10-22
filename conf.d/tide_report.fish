# Tide Report :: Default Configuration

# --- Universal Settings ---
set -q tide_report_service_timeout_millis; or set -g tide_report_service_timeout_millis 3000
set -q tide_report_wttr_url;               or set -g tide_report_wttr_url "https://wttr.in"

# --- Weather Module ---
set -q tide_report_weather_format;           or set -g tide_report_weather_format 2
set -q tide_report_weather_units;            or set -g tide_report_weather_units m
set -q tide_report_weather_location;         or set -g tide_report_weather_location ""
set -q tide_report_weather_refresh_seconds;  or set -g tide_report_weather_refresh_seconds 5
set -q tide_report_weather_expire_seconds;   or set -g tide_report_weather_expire_seconds 10
set -q tide_report_weather_language;         or set -g tide_report_weather_language "en"
set -q tide_report_weather_unavailable_text; or set -g tide_report_weather_unavailable_text "..."
#set -q tide_weather_color;                   or set -g tide_weather_color CCFF00
#set -q tide_weather_bg_color;                or set -g tide_weather_color normal

# --- Moon Module ---
set -q tide_report_moon_format;           or set -g tide_report_moon_format "%m"
set -q tide_report_moon_refresh_seconds;  or set -g tide_report_moon_refresh_seconds 3600
set -q tide_report_moon_expire_seconds;   or set -g tide_report_moon_expire_seconds 7200
set -q tide_report_moon_unavailable_text; or set -g tide_report_moon_unavailable_text "..."
#set -q tide_moon_color;                   or set -g tide_moon_color CCFF00
#set -q tide_moon_bg_color;                or set -g tide_moon_color normal

# --- Tide Module ---
set -q tide_report_tide_station_id;        or set -g tide_report_tide_station_id "" # REQUIRED
set -q tide_report_tide_units;             or set -g tide_report_tide_units "english" # 'english' or 'metric'
set -q tide_report_tide_refresh_seconds;   or set -g tide_report_tide_refresh_seconds 900
set -q tide_report_tide_expire_seconds;    or set -g tide_report_tide_expire_seconds 1800
set -q tide_report_tide_arrow_rising;      or set -g tide_report_tide_arrow_rising "⇞" # Arrow for next high tide
set -q tide_report_tide_arrow_falling;     or set -g tide_report_tide_arrow_falling "⇟" # Arrow for next low tide
set -q tide_report_tide_unavailable_text;  or set -g tide_report_tide_unavailable_text "🌊..."
#set -q tide_tide_color;                    or set -g tide_tide_color CCFF00
#set -q tide_tide_bg_color;                 or set -g tide_tide_color normal
