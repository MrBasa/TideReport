## Tide Report :: Default Configuration

# Moon phase math constants (used by __tide_report_moon_* helpers, session-scoped globals)
set -q __tide_report_moon_PI           || set -g __tide_report_moon_PI (math "acos(-1)")
set -q __tide_report_moon_rad          || set -g __tide_report_moon_rad (math "$__tide_report_moon_PI / 180")
set -q __tide_report_moon_day_seconds  || set -g __tide_report_moon_day_seconds 86400
set -q __tide_report_moon_J1970        || set -g __tide_report_moon_J1970 2440588
set -q __tide_report_moon_J2000        || set -g __tide_report_moon_J2000 2451545
set -q __tide_report_moon_obliquity    || set -g __tide_report_moon_obliquity (math "$__tide_report_moon_rad * 23.4397")

## Install Tide Report defaults and register prompt items on Fisher install event.
function _tide_report_install --description "Install Tide Report defaults and prompt items on fisher event" --on-event tide_report_install
    set -l default_color $tide_time_color
    set -l default_bg_color $tide_time_bg_color
    ## --- Check for Dev Branch Install ---
    if set -q _fisher_plugins; and contains mrbasa/tidereport (string lower $_fisher_plugins)
        echo (set_color --bold bryellow)"WARNING: This is a development branch! Please install from a release tag:"(set_color normal)
        echo "  fisher install MrBasa/TideReport"(set_color cyan --bold)"@v1"(set_color normal)
        sleep 3
    end

    echo (set_color --bold brwhite)"Installing Tide Report Configuration..."(set_color normal)

    ## --- Check dependencies ---
    if ! command -v "gh" 2>/dev/null >/dev/null
        echo (set_color bryellow)"WARNING: Required dependency 'gh' (GitHub CLI) is not installed. Required for github prompt item."(set_color normal)
    end
    if ! command -v "jq" 2>/dev/null >/dev/null
        echo (set_color bryellow)"WARNING: Required dependency 'jq' is not installed. Required for github, tide, weather, and moon items."(set_color normal)
    end
    if ! command -v "curl" 2>/dev/null >/dev/null
        echo (set_color bryellow)"WARNING: Required dependency 'curl' is not installed. Required for weather, moon, and tide prompt items."(set_color normal)
    end

    set -U tide_report_user_agent "tide-report/1.5"
    set -q tide_report_service_timeout_millis || set -U tide_report_service_timeout_millis 6000
    set -q tide_report_wttr_url               || set -U tide_report_wttr_url "https://wttr.in"
    set -q tide_report_weather_provider       || set -U tide_report_weather_provider "openmeteo"
    set -q tide_report_units                  || set -U tide_report_units "m"
    set -q tide_time_format                   || set -U tide_time_format "%H:%M"

    set -q tide_weather_color                      || set -U tide_weather_color $default_color
    set -q tide_weather_bg_color                   || set -U tide_weather_bg_color $default_bg_color
    set -q tide_report_weather_symbol_color        || set -U tide_report_weather_symbol_color white
    set -q tide_report_weather_format              || set -U tide_report_weather_format "%c %t %d%w"
    set -q tide_report_weather_location            || set -U tide_report_weather_location ""
    set -q tide_report_weather_refresh_seconds     || set -U tide_report_weather_refresh_seconds 300
    set -q tide_report_weather_expire_seconds      || set -U tide_report_weather_expire_seconds 900
    set -q tide_report_weather_language            || set -U tide_report_weather_language "en"
    set -q tide_report_weather_unavailable_text    || set -U tide_report_weather_unavailable_text "..."
    set -q tide_report_weather_unavailable_color   || set -U tide_report_weather_unavailable_color red

    set -q tide_moon_color                    || set -U tide_moon_color $default_color
    set -q tide_moon_bg_color                 || set -U tide_moon_bg_color $default_bg_color
    set -q tide_report_moon_provider          || set -U tide_report_moon_provider "local"
    set -q tide_report_moon_refresh_seconds   || set -U tide_report_moon_refresh_seconds 14400
    set -q tide_report_moon_expire_seconds    || set -U tide_report_moon_expire_seconds 28800
    set -q tide_report_moon_unavailable_text  || set -U tide_report_moon_unavailable_text "..."
    set -q tide_report_moon_unavailable_color || set -U tide_report_moon_unavailable_color red

    set -q tide_tide_color                    || set -U tide_tide_color 0087AF
    set -q tide_tide_bg_color                 || set -U tide_tide_bg_color $default_bg_color
    set -q tide_report_tide_station_id        || set -U tide_report_tide_station_id "8443970"
    set -q tide_report_tide_refresh_seconds   || set -U tide_report_tide_refresh_seconds 14400
    set -q tide_report_tide_expire_seconds    || set -U tide_report_tide_expire_seconds 28800
    set -q tide_report_tide_symbol_high       || set -U tide_report_tide_symbol_high "⇞"
    set -q tide_report_tide_symbol_low        || set -U tide_report_tide_symbol_low "⇟"
    set -q tide_report_tide_symbol_color      || set -U tide_report_tide_symbol_color white
    set -q tide_report_tide_unavailable_text  || set -U tide_report_tide_unavailable_text "🌊..."
    set -q tide_report_tide_unavailable_color || set -U tide_report_tide_unavailable_color red
    set -q tide_report_tide_show_level        || set -U tide_report_tide_show_level "true"

    set -q tide_github_color                       || set -U tide_github_color $default_color
    set -q tide_github_bg_color                    || set -U tide_github_bg_color $default_bg_color
    set -q tide_report_github_icon                 || set -U tide_report_github_icon ""
    set -q tide_report_github_icon_stars           || set -U tide_report_github_icon_stars "★"
    set -q tide_report_github_icon_forks           || set -U tide_report_github_icon_forks "⑂"
    set -q tide_report_github_icon_watchers        || set -U tide_report_github_icon_watchers ""
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

    set -q tide_report_weather_units && set -U -e tide_report_weather_units
    set -q tide_report_tide_units && set -U -e tide_report_tide_units
    set -q tide_report_github_color_error && set -U -e tide_report_github_color_error

    _tide_report_ensure_prompt_items 1

    ## --- Prompt item placement message (full install only) ---
    if set -q tide_left_prompt_items; and set -q tide_right_prompt_items
        set -l left $tide_left_prompt_items
        set -l right $tide_right_prompt_items
        set -l our_items github weather moon tide
        set -l skip_placement false
        for item in $our_items
            if contains -- $item $left; or contains -- $item $right
                set skip_placement true
                break
            end
        end
        if $skip_placement
            echo (set_color brwhite)"Tide Report prompt items already present; leaving your prompt configuration unchanged."(set_color normal)
        else
            echo (set_color brwhite)"Adding Tide Report items to your prompt: "(set_color normal)"github (left), weather and moon (right). Tide not added by default."
        end
    end

    echo (set_color brwhite)"New prompt items will show in this shell after reload. In other open terminals, run "(set_color cyan)"tide reload"(set_color brwhite)" or start a new session."(set_color normal)
end

## Handle Fisher update event: clear cache and re-run install logic.
function _tide_report_update --description "Handle fisher update: clear Tide Report cache and re-run install" --on-event tide_report_update
    command rm -rf ~/.cache/tide-report
    _tide_report_install
end

## Uninstall Tide Report: remove prompt items, variables, functions, and cache on Fisher uninstall.
function _tide_report_uninstall --description "Handle fisher uninstall: remove Tide Report items, vars, functions, and cache" --on-event tide_report_uninstall
    echo (set_color --bold brwhite)"Removing Tide Report Configuration & Cache..."(set_color normal)

    # Remove our items from prompt lists first (while vars still exist), then erase universals.
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

    # Erase all universal variables we create. Intentionally leave tide_time_format (Tide core).
    set -l vars_to_erase (set -U --names | string match -r '^_*(tide_report|tide_github|tide_weather|tide_moon|tide_tide).*')
    for v in $vars_to_erase
        set -U -e $v
    end

    # Erase our functions (init handlers, item entry points, helpers)
    builtin functions --erase (builtin functions --all | string match --entire -r '^_*tide_report')

    # Remove cache
    command rm -rf ~/.cache/tide-report

    echo (set_color brwhite)"Run "(set_color cyan)"tide reload"(set_color brwhite)" or start a new session to refresh your prompt."(set_color normal)
end

## Add Tide Report items to Tide prompt lists when none are present (helper used by install).
function _tide_report_ensure_prompt_items --description "Ensure Tide Report items exist in Tide prompt lists" --argument-names silent
    set -q tide_left_prompt_items || return 0
    set -q tide_right_prompt_items || return 0
    set -l left $tide_left_prompt_items
    set -l right $tide_right_prompt_items
    set -l our_items github weather moon tide
    for item in $our_items
        if contains -- $item $left; or contains -- $item $right
            return 0
        end
    end
    set -l new_left
    if contains -- git $left
        for i in $left
            set -a new_left $i
            if test "$i" = "git"
                set -a new_left github
            end
        end
    else if contains -- pwd $left
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
    if test "$silent" != "1"
        echo (set_color brwhite)"Tide Report: added prompt items. Run "(set_color cyan)"tide reload"(set_color brwhite)" if they don't appear."(set_color normal)
    end
end

## User-callable helper to run install logic manually (e.g. when Fisher event does not fire).
function tide_report_install --description "Run Tide Report install manually: add prompt items and set config"
    _tide_report_install
end
