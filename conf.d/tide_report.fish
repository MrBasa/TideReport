# Tide Report :: Default Configuration

# --- Temp Dir ---
set -l tmp_base "$XDG_RUNTIME_DIR"
if not test -d "$tmp_base"
    set tmp_base "/tmp"
end
set -gx _tide_report_tmp_dir "$tmp_base/tide_report"
mkdir -p "$_tide_report_tmp_dir" &>/dev/null

function _tide_report_install --on-event tide_report_install
    echo (set_color brwhite)"Installing Tide Report Configuration..."(set_color normal)

    # Borrow default color from time module to pick up the theme.
    set -l default_color $tide_time_color
    set -l default_bg_color $tide_time_bg_color

    # --- Check dependencies ---
    if ! command -v "gh" &> /dev/null
        echo (set_color bryellow)"WARNING: Required dependency 'gh' (GitHub CLI) is not installed. Required for github prompt item."
    end
    if ! command -v "jq" &> /dev/null
        echo (set_color bryellow)"WARNING: Required dependency 'jq' is not installed. Required for github and tide prompt items."
    end
    if ! command -v "curl" &> /dev/null
        echo (set_color bryellow)"WARNING: Required dependency 'curl' is not installed. Required for weather, moon, and tide prompt items."
    end

    # --- Universal Settings ---
    set -q tide_report_service_timeout_millis || set -U tide_report_service_timeout_millis 3000
    set -q tide_report_wttr_url               || set -U tide_report_wttr_url "https://wttr.in"

    # --- Weather Module ---
    set -q tide_weather_color                      || set -U tide_weather_color $default_color
    set -q tide_weather_bg_color                   || set -U tide_weather_bg_color $default_bg_color
    set -q tide_report_weather_format              || set -U tide_report_weather_format 2
    set -q tide_report_weather_units               || set -U tide_report_weather_units m
    set -q tide_report_weather_location            || set -U tide_report_weather_location ""
    set -q tide_report_weather_refresh_seconds     || set -U tide_report_weather_refresh_seconds 300 # 5 minutes
    set -q tide_report_weather_expire_seconds      || set -U tide_report_weather_expire_seconds 600 # 10 minutes
    set -q tide_report_weather_language            || set -U tide_report_weather_language "en"
    set -q tide_report_weather_unavailable_text    || set -U tide_report_weather_unavailable_text ""
    set -q tide_report_weather_unavailable_color   || set -U tide_report_weather_unavailable_color brred

    # --- Moon Module ---
    set -q tide_moon_color                    || set -U tide_moon_color $default_color
    set -q tide_moon_bg_color                 || set -U tide_moon_bg_color $default_bg_color
    set -q tide_report_moon_format            || set -U tide_report_moon_format "%m"
    set -q tide_report_moon_refresh_seconds   || set -U tide_report_moon_refresh_seconds 14400 # 4 hours
    set -q tide_report_moon_expire_seconds    || set -U tide_report_moon_expire_seconds 28800 # 8 hours
    set -q tide_report_moon_unavailable_text  || set -U tide_report_moon_unavailable_text ""
    set -q tide_report_moon_unavailable_color || set -U tide_report_moon_unavailable_color brred

    # --- Tide Module ---
    set -q tide_tide_color                    || set -U tide_tide_color 303f9f
    set -q tide_tide_bg_color                 || set -U tide_tide_bg_color $default_bg_color
    set -q tide_report_tide_station_id        || set -U tide_report_tide_station_id "8443970" # Boston
    set -q tide_report_tide_units             || set -U tide_report_tide_units "metric" # 'english' or 'metric'
    set -q tide_report_tide_refresh_seconds   || set -U tide_report_tide_refresh_seconds 14400 # 4 hours
    set -q tide_report_tide_expire_seconds    || set -U tide_report_tide_expire_seconds 28800 # 8 hours
    set -q tide_report_tide_symbol_high       || set -U tide_report_tide_symbol_high "⇞" # Arrow for next high tide
    set -q tide_report_tide_symbol_low        || set -U tide_report_tide_symbol_low "⇟" # Arrow for next low tide
    set -q tide_report_tide_symbol_color      || set -U tide_report_tide_symbol_color brwhite
    set -q tide_report_tide_unavailable_text  || set -U tide_report_tide_unavailable_text "🌊"
    set -q tide_report_tide_unavailable_color || set -U tide_report_tide_unavailable_color brred
    set -q tide_report_tide_show_level        || set -U tide_report_tide_show_level "true"

    # --- GitHub Module ---
    set -q tide_github_color                  || set -U tide_github_color white
    set -q tide_github_bg_color               || set -U tide_github_bg_color $default_bg_color
    set -q tide_report_github_icon            || set -U tide_report_github_icon ""
    set -q tide_report_github_color_stars     || set -U tide_report_github_color_stars bryellow
    set -q tide_report_github_color_forks     || set -U tide_report_github_color_forks bryellow
    set -q tide_report_github_color_issues    || set -U tide_report_github_color_issues bryellow
    set -q tide_report_github_color_prs       || set -U tide_report_github_color_prs bryellow
    set -q tide_report_github_refresh_seconds || set -U tide_report_github_refresh_seconds 30

    tide reload
end

function _tide_report_update --on-event tide_report_update
    command rm -rf ~/.cache/tide-report
    _tide_report_install
end

function _tide_report_uninstall --on-event tide_report_uninstall
    echo (set_color brwhite)"Removing Tide Report Configuration..."(set_color normal)

    # Delete vars
    set -l vars_to_erase (set -U --names | string match -r '^_?(tide_report|tide_github|tide_weather|tide_moon|tide_tide).*')

    if test (count $vars_to_erase) -gt 0
        set -U -e $vars_to_erase
    end

    # Delete funcs
    builtin functions --erase (builtin functions --all | string match --entire -r '^_?tide_report')

    # Remove Tide Report items from left and right prompts
    if set -q tide_right_prompt_items
        set -U tide_right_prompt_items (string match -rv '^(github|weather|moon|tide)$' $tide_right_prompt_items)
    end

    if set -q tide_left_prompt_items
        set -U tide_left_prompt_items (string match -rv '^(github|weather|moon|tide)$' $tide_left_prompt_items)
    end

    command rm -rf ~/.cache/tide-report

    tide reload
end
