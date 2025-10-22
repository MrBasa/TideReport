# Tide Report :: Default Configuration

function _tide_report_install --on-event tide_report_install
    echo "Installing Tide Report Configuration..."

    # Borrow default color from time to pick up the theme.
    set -l default_color $tide_time_color       || set -l default_color 5F8787
    set -l default_bg_color $tide_time_bg_color || set -l default_bg_color 303030

    # --- Universal Settings ---
    set -q tide_report_service_timeout_millis  || set -Ux tide_report_service_timeout_millis 3000
    set -q tide_report_wttr_url                || set -Ux tide_report_wttr_url "https://wttr.in"

    # --- Weather Module ---
    set -q tide_report_weather_format            || set -Ux tide_report_weather_format 2
    set -q tide_report_weather_units             || set -Ux tide_report_weather_units m
    set -q tide_report_weather_location          || set -Ux tide_report_weather_location ""
    set -q tide_report_weather_refresh_seconds   || set -Ux tide_report_weather_refresh_seconds 5
    set -q tide_report_weather_expire_seconds    || set -Ux tide_report_weather_expire_seconds 10
    set -q tide_report_weather_language          || set -Ux tide_report_weather_language "en"
    set -q tide_report_weather_unavailable_text  || set -Ux tide_report_weather_unavailable_text ""
    set -q tide_report_weather_unavailable_color || set -Ux tide_report_weather_unavailable_color red
    set -q tide_weather_color                    || set -Ux tide_weather_color $default_color
    set -q tide_weather_bg_color                 || set -Ux tide_weather_bg_color $default_bg_color

    # --- Moon Module ---
    set -q tide_report_moon_format            || set -Ux tide_report_moon_format "%m"
    set -q tide_report_moon_refresh_seconds   || set -Ux tide_report_moon_refresh_seconds 3600
    set -q tide_report_moon_expire_seconds    || set -Ux tide_report_moon_expire_seconds 7200
    set -q tide_report_moon_unavailable_text  || set -Ux tide_report_moon_unavailable_text ""
    set -q tide_report_moon_unavailable_color || set -Ux tide_report_moon_unavailable_color red
    set -q tide_moon_color                    || set -Ux tide_moon_color $default_color
    set -q tide_moon_bg_color                 || set -Ux tide_moon_bg_color $default_bg_color

    # --- Tide Module ---
    set -q tide_report_tide_station_id        || set -Ux tide_report_tide_station_id "9087044" # REQUIRED 8443970
    set -q tide_report_tide_units             || set -Ux tide_report_tide_units "english" # 'english' or 'metric'
    set -q tide_report_tide_refresh_seconds   || set -Ux tide_report_tide_refresh_seconds 900
    set -q tide_report_tide_expire_seconds    || set -Ux tide_report_tide_expire_seconds 1800
    set -q tide_report_tide_arrow_rising      || set -Ux tide_report_tide_arrow_rising "⇞" # Arrow for next high tide
    set -q tide_report_tide_arrow_falling     || set -Ux tide_report_tide_arrow_falling "⇟" # Arrow for next low tide
    set -q tide_report_tide_unavailable_text  || set -Ux tide_report_tide_unavailable_text "🌊X"
    set -q tide_report_tide_unavailable_color || set -Ux tide_report_tide_unavailable_color red
    set -q tide_tide_color                    || set -Ux tide_tide_color $default_color
    set -q tide_tide_bg_color                 || set -Ux tide_tide_bg_color $default_bg_color
end

function _tide_report_update --on-event tide_report_update
    _tide_report_install
end

function _tide_report_uninstall --on-event tide_report_uninstall
    echo "Removing Tide Report Configuration..."

    # Delete vars
    set -l vars_to_erase
    set -a vars_to_erase (set -U --names | string match --entire -r '^_?tide_report')
    set -a vars_to_erase (set -U --names | string match --entire -r '^_?tide_weather')
    set -a vars_to_erase (set -U --names | string match --entire -r '^_?tide_moon')
    set -a vars_to_erase (set -U --names | string match --entire -r '^_?tide_tide')

    if test -n "$vars_to_erase"
        set -e $vars_to_erase
    end

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
