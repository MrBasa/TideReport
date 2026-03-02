# Tide Report :: Default Configuration

# User-Agent for HTTP requests (single source of truth; bump with each release)
set -q tide_report_user_agent || set -U tide_report_user_agent "tide-report/1.4"

function _tide_report_install --on-event tide_report_install
    # --- Check for Dev Branch Install ---
    if contains mrbasa/tidereport (string lower $_fisher_plugins)
        echo (set_color --bold bryellow)"WARNING: This is a development branch! Please install from a release tag:"(set_color normal)
        echo "  fisher install MrBasa/TideReport"(set_color cyan --bold)"@v1"(set_color normal)
        sleep 3
    end

    echo (set_color --bold brwhite)"Installing Tide Report Configuration..."(set_color normal)

    # Borrow default color from time module to pick up the theme.
    set -l default_color $tide_time_color
    set -l default_bg_color $tide_time_bg_color

    # --- Check dependencies ---
    if ! command -v "gh" 2>/dev/null >/dev/null
        echo (set_color bryellow)"WARNING: Required dependency 'gh' (GitHub CLI) is not installed. Required for github prompt item."(set_color normal)
    end
    if ! command -v "jq" 2>/dev/null >/dev/null
        # jq is now required for weather and moon as well
        echo (set_color bryellow)"WARNING: Required dependency 'jq' is not installed. Required for github, tide, weather, and moon items."(set_color normal)
    end
    if ! command -v "curl" 2>/dev/null >/dev/null
        echo (set_color bryellow)"WARNING: Required dependency 'curl' is not installed. Required for weather, moon, and tide prompt items."(set_color normal)
    end

    # --- Universal Settings ---
    set -U tide_report_user_agent "tide-report/1.4"
    set -q tide_report_service_timeout_millis || set -U tide_report_service_timeout_millis 6000
    set -q tide_report_wttr_url               || set -U tide_report_wttr_url "https://wttr.in"
    set -q tide_report_weather_provider       || set -U tide_report_weather_provider "openmeteo" # 'wttr' | 'openmeteo'
    set -q tide_report_units                  || set -U tide_report_units "m" # 'm' (Metric), 'u' (USCS)
    set -q tide_time_format                   || set -U tide_time_format "%H:%M" # Time format for tide

    # --- Weather Module ---
    # Humidity:💧 Sunrise:🌅,🌄,󰖜, Sunset:🌇,🌆,󰖚,󰖛, UV:☀️,😎,🕶️,🕶,󰓠 Temp:🌡️,󰔅,󰔄, Feels:🧖,🧖‍♂️,🥵,🤒,,
    # set -U tide_report_weather_format "%c 🌡️%t (%f) %d%w 💧%h ☀️%u 󰖜%S 󰖚%s"
    set -q tide_weather_color                      || set -U tide_weather_color $default_color
    set -q tide_weather_bg_color                   || set -U tide_weather_bg_color $default_bg_color
    set -q tide_report_weather_symbol_color        || set -U tide_report_weather_symbol_color white
    set -q tide_report_weather_format              || set -U tide_report_weather_format "%c %t %d%w" # See README
    set -q tide_report_weather_location            || set -U tide_report_weather_location "" # Empty => IP-based location
    set -q tide_report_weather_refresh_seconds     || set -U tide_report_weather_refresh_seconds 300 # 5 minutes
    set -q tide_report_weather_expire_seconds      || set -U tide_report_weather_expire_seconds 900 # 15 minutes
    set -q tide_report_weather_language            || set -U tide_report_weather_language "en"
    set -q tide_report_weather_unavailable_text    || set -U tide_report_weather_unavailable_text "..."
    set -q tide_report_weather_unavailable_color   || set -U tide_report_weather_unavailable_color red

    # --- Moon Module ---
    set -q tide_moon_color                    || set -U tide_moon_color $default_color
    set -q tide_moon_bg_color                 || set -U tide_moon_bg_color $default_bg_color
    set -q tide_report_moon_provider          || set -U tide_report_moon_provider "potmt" # 'potmt' | 'wttr'
    set -q tide_report_moon_potmt_url         || set -U tide_report_moon_potmt_url "https://api.phaseofthemoontoday.com/v1/current"
    set -q tide_report_moon_refresh_seconds   || set -U tide_report_moon_refresh_seconds 14400 # 4 hours
    set -q tide_report_moon_expire_seconds    || set -U tide_report_moon_expire_seconds 28800 # 8 hours
    set -q tide_report_moon_unavailable_text  || set -U tide_report_moon_unavailable_text "..."
    set -q tide_report_moon_unavailable_color || set -U tide_report_moon_unavailable_color red

    # --- Tide Module ---
    set -q tide_tide_color                    || set -U tide_tide_color 0087AF
    set -q tide_tide_bg_color                 || set -U tide_tide_bg_color $default_bg_color
    set -q tide_report_tide_station_id        || set -U tide_report_tide_station_id "8443970" # Boston
    set -q tide_report_tide_refresh_seconds   || set -U tide_report_tide_refresh_seconds 14400 # 4 hours
    set -q tide_report_tide_expire_seconds    || set -U tide_report_tide_expire_seconds 28800 # 8 hours
    set -q tide_report_tide_symbol_high       || set -U tide_report_tide_symbol_high "⇞" # Arrow for next high tide
    set -q tide_report_tide_symbol_low        || set -U tide_report_tide_symbol_low "⇟" # Arrow for next low tide
    set -q tide_report_tide_symbol_color      || set -U tide_report_tide_symbol_color white
    set -q tide_report_tide_unavailable_text  || set -U tide_report_tide_unavailable_text "🌊..."
    set -q tide_report_tide_unavailable_color || set -U tide_report_tide_unavailable_color red
    set -q tide_report_tide_show_level        || set -U tide_report_tide_show_level "true"

    # --- GitHub Module ---
    set -q tide_github_color                       || set -U tide_github_color white
    set -q tide_github_bg_color                    || set -U tide_github_bg_color $default_bg_color
    set -q tide_report_github_icon                 || set -U tide_report_github_icon ""
    set -q tide_report_github_icon_stars           || set -U tide_report_github_icon_stars "★"
    set -q tide_report_github_icon_forks           || set -U tide_report_github_icon_forks "⑂"
    set -q tide_report_github_icon_watchers        || set -U tide_report_github_icon_watchers "" #"👁"
    set -q tide_report_github_icon_issues          || set -U tide_report_github_icon_issues "!"
    set -q tide_report_github_icon_prs             || set -U tide_report_github_icon_prs "PR"
    set -q tide_report_github_color_stars          || set -U tide_report_github_color_stars yellow
    set -q tide_report_github_color_forks          || set -U tide_report_github_color_forks $tide_report_github_color_stars
    set -q tide_report_github_color_watchers       || set -U tide_report_github_color_watchers $tide_report_github_color_stars
    set -q tide_report_github_color_issues         || set -U tide_report_github_color_issues $tide_report_github_color_stars
    set -q tide_report_github_color_prs            || set -U tide_report_github_color_prs $tide_report_github_color_stars
    set -q tide_report_github_unavailable_text     || set -U tide_report_github_unavailable_text "..."
    set -q tide_report_github_unavailable_color    || set -U tide_report_github_unavailable_color red
    set -q tide_report_github_refresh_seconds      || set -U tide_report_github_refresh_seconds 30

    # Clean up old variables
    set -q tide_report_weather_units && set -U -e tide_report_weather_units
    set -q tide_report_tide_units && set -U -e tide_report_tide_units
    set -q tide_report_github_color_error && set -U -e tide_report_github_color_error

    # --- Prompt item placement (fresh install only) ---
    set -l left
    set -l right
    set -q tide_left_prompt_items && set left $tide_left_prompt_items
    set -q tide_right_prompt_items && set right $tide_right_prompt_items
    set -l our_items github weather moon tide
    set -l skip_placement false
    for item in $our_items
        if contains $item $left; or contains $item $right
            set skip_placement true
            break
        end
    end
    if $skip_placement
        echo (set_color brwhite)"Tide Report prompt items already present; leaving your prompt configuration unchanged."(set_color normal)
    else
        echo (set_color brwhite)"Adding Tide Report items to your prompt: "(set_color normal)"github (left), weather and moon (right). Tide not added by default."
        set -l new_left
        if contains git $left
            for i in $left
                set -a new_left $i
                if test "$i" = "git"
                    set -a new_left github
                end
            end
        else if contains pwd $left
            for i in $left
                if test "$i" = "pwd"
                    set -a new_left github
                end
                set -a new_left $i
            end
        else
            set new_left $left github
        end
        set -l new_right $right weather moon
        set -U tide_left_prompt_items $new_left
        set -U tide_right_prompt_items $new_right
    end

    echo (set_color brwhite)"New prompt items will show in this shell after reload. In other open terminals, run "(set_color cyan)"tide reload"(set_color brwhite)" or start a new session."(set_color normal)
    tide reload
end

function _tide_report_update --on-event tide_report_update
    command rm -rf ~/.cache/tide-report
    _tide_report_install
end

function _tide_report_uninstall --on-event tide_report_uninstall
    echo (set_color --bold brwhite)"Removing Tide Report Configuration & Cache..."(set_color normal)

    # Remove our items from prompt lists first (while vars still exist), then erase universals.
    # We do not remove tide_time_format (shared with Tide's time item; we only set it when unset).
    set -l tide_report_items github weather moon tide
    if set -q tide_right_prompt_items
        set -l new_right
        for item in $tide_right_prompt_items
            if not contains -- $item $tide_report_items
                set -a new_right $item
            end
        end
        set -U tide_right_prompt_items $new_right
    end
    if set -q tide_left_prompt_items
        set -l new_left
        for item in $tide_left_prompt_items
            if not contains -- $item $tide_report_items
                set -a new_left $item
            end
        end
        set -U tide_left_prompt_items $new_left
    end

    # Erase all universal variables we create: tide_report_*, tide_github_*, tide_weather_*,
    # tide_moon_*, tide_tide_*, and any _tide_report_* (e.g. lock vars). Intentionally leave
    # tide_time_format (Tide core variable).
    set -l vars_to_erase (set -U --names | string match -r '^_?(tide_report|tide_github|tide_weather|tide_moon|tide_tide).*')
    for v in $vars_to_erase
        set -U -e $v
    end

    # Erase our functions (item entry points and helpers)
    builtin functions --erase (builtin functions --all | string match --entire -r '^_?tide_report')

    # Remove cache
    command rm -rf ~/.cache/tide-report

    tide reload
end
