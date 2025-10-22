# Tide Report :: Default Configuration

function _tide_report_install --on-event tide_report_install
    echo "Installing Tide Report Configuration..."
    # --- Universal Settings ---
    set -q tide_report_service_timeout_millis  || set -Ux tide_report_service_timeout_millis 3000
    set -q tide_report_wttr_url                || set -Ux tide_report_wttr_url "https://wttr.in"

    # --- Weather Module ---
    set -q tide_report_weather_format            || set -u tide_report_weather_format 2
    set -q tide_report_weather_units             || set -Ux tide_report_weather_units m
    set -q tide_report_weather_location          || set -Ux tide_report_weather_location ""
    set -q tide_report_weather_refresh_seconds   || set -Ux tide_report_weather_refresh_seconds 5
    set -q tide_report_weather_expire_seconds    || set -Ux tide_report_weather_expire_seconds 10
    set -q tide_report_weather_language          || set -Ux tide_report_weather_language "en"
    set -q tide_report_weather_unavailable_text  || set -Ux tide_report_weather_unavailable_text ""
    set -q tide_report_weather_unavailable_color || set -Ux tide_report_weather_unavailable_color red
    #set -q tide_weather_color                    || set -Ux tide_weather_color CCFF00
    #set -q tide_weather_bg_color                 || set -Ux tide_weather_color normal

    # --- Moon Module ---
    set -q tide_report_moon_format            || set -Ux tide_report_moon_format "%m"
    set -q tide_report_moon_refresh_seconds   || set -Ux tide_report_moon_refresh_seconds 3600
    set -q tide_report_moon_expire_seconds    || set -Ux tide_report_moon_expire_seconds 7200
    set -q tide_report_moon_unavailable_text  || set -Ux tide_report_moon_unavailable_text ""
    set -q tide_report_moon_unavailable_color || set -Ux tide_report_moon_unavailable_color red
    #set -q tide_moon_color                    || set -Ux tide_moon_color CCFF00
    #set -q tide_moon_bg_color                 || set -Ux tide_moon_color normal

    # --- Tide Module ---
    set -q tide_report_tide_station_id        || set -Ux tide_report_tide_station_id "" # REQUIRED
    set -q tide_report_tide_units             || set -Ux tide_report_tide_units "english" # 'english' or 'metric'
    set -q tide_report_tide_refresh_seconds   || set -Ux tide_report_tide_refresh_seconds 900
    set -q tide_report_tide_expire_seconds    || set -Ux tide_report_tide_expire_seconds 1800
    set -q tide_report_tide_arrow_rising      || set -Ux tide_report_tide_arrow_rising "⇞" # Arrow for next high tide
    set -q tide_report_tide_arrow_falling     || set -Ux tide_report_tide_arrow_falling "⇟" # Arrow for next low tide
    set -q tide_report_tide_unavailable_text  || set -Ux tide_report_tide_unavailable_text "🌊"
    set -q tide_report_tide_unavailable_color || set -Ux tide_report_tide_unavailable_color red
    #set -q tide_tide_color                    || set -Ux tide_tide_color CCFF00
    #set -q tide_tide_bg_color                 || set -Ux tide_tide_color normal
end

function _tide_report_update --on-event tide_report_update
    _tide_fish_colorize "Doing a update..."
    _tide_report_install
end

function _tide_report_uninstall --on-event _tide_report_uninstall
    echo "Removing Tide Report Configuration..."

    # Delete vars
    set -e (set -U --names | string match --entire -r '^_?tide_report')

    # Delete funcs
    builtin functions --erase (builtin functions --all | string match --entire -r '^_?tide_report')

    # Remove items from left and right prompts
    if set -q tide_right_prompt_items
        set -U tide_right_prompt_items (string match -rv '^(weather|moon|tide)$' $tide_right_prompt_items)
    end

    if set -q tide_left_prompt_items
        set -U tide_left_prompt_items (string match -rv '^(weather|moon|tide)$' $tide_left_prompt_items)
    end
end
