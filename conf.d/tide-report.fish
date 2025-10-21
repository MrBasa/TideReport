# tide-report :: Default Configuration

# --- Universal Settings ---
# Timeout for all web requests, in milliseconds.
set -q tide-report_service_timeout_millis; or set -g tide_report_service_timeout_millis 3000

# --- Weather Module ---
set -q tide-report_weather_format;           or set -g tide_report_weather_format 2
# ... (rest of weather settings are the same) ...
set -q tide-report_weather_unavailable_text; or set -g tide_report_weather_unavailable_text "..."

# --- Moon Module ---
set -q tide-report_moon_format;           or set -g tide_report_moon_format "%m"
# ... (rest of moon settings are the same) ...
set -q tide-report_moon_unavailable_text; or set -g tide_report_moon_unavailable_text "..."

# --- Tide Module (New) ---
set -q tide-report_tide_station_id;        or set -g tide_report_tide_station_id "" # REQUIRED
set -q tide-report_tide_units;             or set -g tide_report_tide_units "english" # 'english' or 'metric'
set -q tide-report_tide_refresh_seconds;   or set -g tide_report_tide_refresh_seconds 900
set -q tide-report_tide_expire_seconds;    or set -g tide_report_tide_expire_seconds 1800
set -q tide-report_tide_arrow_rising;      or set -g tide_report_tide_arrow_rising "⇞" # Arrow for next high tide
set -q tide-report_tide_arrow_falling;     or set -g tide_report_tide_arrow_falling "⇟" # Arrow for next low tide
set -q tide-report_tide_unavailable_text;  or set -g tide_report_tide_unavailable_text "🌊..."

