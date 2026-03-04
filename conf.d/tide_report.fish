## Tide Report :: Default Configuration

## Plugin version (single source of truth for display and API client string)
set -g _tide_report_version "1.5"
set -q tide_report_user_agent || set -U tide_report_user_agent "tide-report/$_tide_report_version"
set -q tide_report_log_expected || set -U tide_report_log_expected 1

# Moon phase math constants (used by __tide_report_moon_* helpers, session-scoped globals)
set -q __tide_report_moon_PI           || set -g __tide_report_moon_PI (math "acos(-1)")
set -q __tide_report_moon_rad          || set -g __tide_report_moon_rad (math "$__tide_report_moon_PI / 180")
set -q __tide_report_moon_day_seconds  || set -g __tide_report_moon_day_seconds 86400
set -q __tide_report_moon_J1970        || set -g __tide_report_moon_J1970 2440588
set -q __tide_report_moon_J2000        || set -g __tide_report_moon_J2000 2451545
set -q __tide_report_moon_obliquity    || set -g __tide_report_moon_obliquity (math "$__tide_report_moon_rad * 23.4397")

## If user has prompt item lists set globally (e.g. in config.fish), inform them and show copy-paste lines.
## Arguments: left_list and right_list as space-separated strings (the lists we just wrote). Either may be empty.
function _tide_report_warn_global_prompt_items --description "Warn when a global shadows; show session fix and config.fish line" --argument-names left_list right_list
    set -q left_list || set left_list ""
    set -q right_list || set right_list ""
    set -q -g tide_left_prompt_items; or set -q -g tide_right_prompt_items; or return 0
    echo (set_color bryellow)"You have tide_left_prompt_items and/or tide_right_prompt_items set globally (e.g. in config.fish), which overrides the list we just updated."(set_color normal)
    echo (set_color brwhite)"To see the change in this session, run:"(set_color normal)
    echo (set_color cyan)"  set -e -g tide_left_prompt_items ; set -e -g tide_right_prompt_items ; tide reload"(set_color normal)
    echo (set_color brwhite)"To make it permanent, update the corresponding line(s) in your config.fish. Example:"(set_color normal)
    test -n "$left_list" && echo (set_color cyan)"  set -g tide_left_prompt_items $left_list"(set_color normal)
    test -n "$right_list" && echo (set_color cyan)"  set -g tide_right_prompt_items $right_list"(set_color normal)
end

## Show sample render of each Tide Report prompt item (for install wizard). Optional weather_format: concise, medium, or detailed.
function _tide_report_install_show_preview --description "Echo labeled sample output for github, weather, moon, tide" --argument-names weather_format
    set -q tide_github_color || set -l tide_github_color white
    set -q tide_weather_color || set -l tide_weather_color white
    set -q tide_moon_color || set -l tide_moon_color white
    set -q tide_tide_color || set -l tide_tide_color 0087AF
    set -q tide_report_github_icon || set -l tide_report_github_icon ""
    set -q tide_report_github_icon_stars || set -l tide_report_github_icon_stars "★"
    set -q tide_report_github_icon_forks || set -l tide_report_github_icon_forks "⑂"
    set -q tide_report_tide_symbol_high || set -l tide_report_tide_symbol_high "⇞"
    set -q tide_report_tide_symbol_color || set -l tide_report_tide_symbol_color white

    set -l star_color yellow
    set -q tide_report_github_color_stars && set star_color $tide_report_github_color_stars
    set -q tide_report_github_show_ci || set -l tide_report_github_show_ci true
    set -q tide_report_github_icon_ci_pass || set -l tide_report_github_icon_ci_pass "✓"
    set -q tide_report_github_color_ci_pass || set -l tide_report_github_color_ci_pass green
    set -l github_preview (set_color $tide_github_color)"$tide_report_github_icon "(set_color $star_color)"$tide_report_github_icon_stars 42 $tide_report_github_icon_forks 3"
    if test "$tide_report_github_show_ci" = true
        set github_preview "$github_preview "(set_color $tide_report_github_color_ci_pass)$tide_report_github_icon_ci_pass
    end
    echo (set_color brwhite)"[1] github:   "(set_color normal)"$github_preview"(set_color normal)
    switch "$weather_format"
        case concise
            echo (set_color brwhite)"[2] weather:  "(set_color normal)(set_color $tide_weather_color)"☀️ +22°"(set_color normal)
        case detailed
            echo (set_color brwhite)"[2] weather:  "(set_color normal)(set_color $tide_weather_color)"☀️🌡️+22° (+21°) 65% ⬇12km/h"(set_color normal)
        case "*"
            echo (set_color brwhite)"[2] weather:  "(set_color normal)(set_color $tide_weather_color)"☀️ +22° ⬇12km/h"(set_color normal)
    end
    echo (set_color brwhite)"[3] moon:     "(set_color normal)(set_color $tide_moon_color)"🌕"(set_color normal)
    echo (set_color brwhite)"[4] tide:     "(set_color normal)(set_color $tide_report_tide_symbol_color)"$tide_report_tide_symbol_high"(set_color $tide_tide_color)" 14:30 3.2m"(set_color normal)
end

## Install Tide Report defaults and register prompt items on Fisher install event.
function _tide_report_install --description "Install Tide Report defaults and prompt items on fisher event" --on-event tide_report_install
    set -l default_color $tide_time_color
    set -l default_bg_color $tide_time_bg_color
    ## --- Check for Dev Branch Install ---
    ## Dev = TideReport entry has no @version (e.g. local path or MrBasa/TideReport without @v1).
    set -l _is_dev_install false
    if set -q _fisher_plugins
        for _p in $_fisher_plugins
            if string match -q '*tidereport*' (string lower -- "$_p")
                if not string match -q '*@*' "$_p"
                    set _is_dev_install true
                    break
                end
            end
        end
    end
    if test "$_is_dev_install" = true
        echo (set_color --bold bryellow)"WARNING: This is a development branch! Please install from a release tag:"(set_color normal)
        echo "  fisher install MrBasa/TideReport"(set_color cyan --bold)"@v1"(set_color normal)
        sleep 3
    end

    echo (set_color --bold brwhite)"Installing Tide Report v$_tide_report_version..."(set_color normal)

    ## --- Check dependencies ---
    if ! command -v "gh" 2>/dev/null >/dev/null
        echo (set_color bryellow)"WARNING: Required dependency 'gh' (GitHub CLI) is not installed. Required for github prompt item."(set_color normal)
        functions -q __tide_report_log_expected && __tide_report_log_expected dependency "gh not installed"
    end
    if ! command -v "jq" 2>/dev/null >/dev/null
        echo (set_color bryellow)"WARNING: Required dependency 'jq' is not installed. Required for github, tide, weather, and moon items."(set_color normal)
        functions -q __tide_report_log_expected && __tide_report_log_expected dependency "jq not installed"
    end
    if ! command -v "curl" 2>/dev/null >/dev/null
        echo (set_color bryellow)"WARNING: Required dependency 'curl' is not installed. Required for weather, moon, and tide prompt items."(set_color normal)
        functions -q __tide_report_log_expected && __tide_report_log_expected dependency "curl not installed"
    end

    set -U tide_report_user_agent "tide-report/$_tide_report_version"
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
    set -q tide_report_github_show_ci              || set -U tide_report_github_show_ci true
    set -q tide_report_github_icon_ci_pass         || set -U tide_report_github_icon_ci_pass "✓"
    set -q tide_report_github_icon_ci_fail         || set -U tide_report_github_icon_ci_fail "✗"
    set -q tide_report_github_icon_ci_pending     || set -U tide_report_github_icon_ci_pending "⋯"
    set -q tide_report_github_color_ci_pass        || set -U tide_report_github_color_ci_pass green
    set -q tide_report_github_color_ci_fail        || set -U tide_report_github_color_ci_fail red
    set -q tide_report_github_color_ci_pending     || set -U tide_report_github_color_ci_pending yellow
    set -q tide_report_github_ci_refresh_seconds   || set -U tide_report_github_ci_refresh_seconds 60

    set -q tide_report_weather_units && set -U -e tide_report_weather_units
    set -q tide_report_tide_units && set -U -e tide_report_tide_units
    set -q tide_report_github_color_error && set -U -e tide_report_github_color_error

    if not set -q tide_left_prompt_items; or not set -q tide_right_prompt_items
        _tide_report_ensure_prompt_items 1
        tide reload 2>/dev/null; or true
        return 0
    end
    set -l left $tide_left_prompt_items
    set -l right $tide_right_prompt_items
    set -l our_items github weather moon tide
    set -l any_present false
    for item in $our_items
        if contains -- $item $left; or contains -- $item $right
            set any_present true
            break
        end
    end

    if $any_present
        echo (set_color brwhite)"Tide Report prompt items already present; leaving your prompt configuration unchanged."(set_color normal)
        tide reload 2>/dev/null; or true
    else if not status is-interactive
        _tide_report_ensure_prompt_items 1
        tide reload 2>/dev/null; or true
        echo (set_color brwhite)"Tide Report: added github (left), weather, moon (right). Run "(set_color cyan)"tide reload"(set_color brwhite)" if they don't appear."(set_color normal)
    else
        echo (set_color brwhite)"Choose which Tide Report items to add to your prompt."(set_color normal)
        _tide_report_install_show_preview medium
        echo ""

        set -l add_github false
        read -l -P (set_color brwhite)"Add GitHub to prompt? [Y/n]: "(set_color normal) reply
        set -l r (string trim (string lower -- "$reply"))
        if test -z "$r"; or test "$r" = "y"; or test "$r" = "yes"
            set add_github true
        end
        if $add_github
            read -l -P (set_color brwhite)"Show CI status in GitHub item? [Y/n]: "(set_color normal) reply
            set -l r (string trim (string lower -- "$reply"))
            if test -z "$r"; or test "$r" = "y"; or test "$r" = "yes"
                set -U tide_report_github_show_ci true
            else if test "$r" = "n"; or test "$r" = "no"
                set -U tide_report_github_show_ci false
            end
        end

        set -l add_weather false
        read -l -P (set_color brwhite)"Add Weather to prompt? [Y/n]: "(set_color normal) reply
        set -l r (string trim (string lower -- "$reply"))
        if test -z "$r"; or test "$r" = "y"; or test "$r" = "yes"
            set add_weather true
        end

        set -l add_moon false
        read -l -P (set_color brwhite)"Add Moon to prompt? [Y/n]: "(set_color normal) reply
        set -l r (string trim (string lower -- "$reply"))
        if test -z "$r"; or test "$r" = "y"; or test "$r" = "yes"
            set add_moon true
        end

        set -l add_tide false
        read -l -P (set_color brwhite)"Add Tide to prompt? [y/N]: "(set_color normal) reply
        set -l r (string trim (string lower -- "$reply"))
        if test -n "$r"; and test "$r" != "n"; and test "$r" != "no"
            if test "$r" = "y"; or test "$r" = "yes"
                set add_tide true
            end
        end
        if $add_weather
            read -l -P (set_color brwhite)"Weather format? 1=concise 2=medium 3=detailed [2]: "(set_color normal) format_choice
            set -l fmt "2"
            if test -n "$format_choice"
                string match -q -r '^[1-3]$' -- $format_choice && set fmt $format_choice
            end
            switch "$fmt"
                case 1; set -U tide_report_weather_format "%c %t"
                case 3; set -U tide_report_weather_format "%c 🌡️%t (%f) %h %d%w"
                case "*"; set -U tide_report_weather_format "%c %t %d%w"
            end
            ## Location step: show IP result or prompt manual input; validate and confirm.
            set -l ip_line ""
            if command -q curl; and command -q jq
                set -l ip_data (curl -s -A "$tide_report_user_agent" --max-time 5 "http://ip-api.com/json/?fields=lat,lon,city,regionName,country")
                if test $status -eq 0; and test -n "$ip_data"
                    set -l _lat (printf "%s" "$ip_data" | jq -r '.lat // empty')
                    set -l _lon (printf "%s" "$ip_data" | jq -r '.lon // empty')
                    set -l _city (printf "%s" "$ip_data" | jq -r '.city // empty')
                    set -l _region (printf "%s" "$ip_data" | jq -r '.regionName // empty')
                    set -l _country (printf "%s" "$ip_data" | jq -r '.country // empty')
                    if test -n "$_lat"; and test -n "$_lon"
                        set -l _parts $_city $_region $_country
                        set ip_line (string join ", " $_parts)" ($_lat, $_lon)"
                    end
                end
            end
            set -l use_ip true
            if test -n "$ip_line"
                read -l -P (set_color brwhite)"Detected location: $ip_line. Use this location? [Y/n]: "(set_color normal) reply
                set -l r (string trim (string lower -- "$reply"))
                if test "$r" = "n"; or test "$r" = "no"
                    set use_ip false
                end
            else
                set use_ip false
            end
            set -l first_manual_prompt true
            set -l location_tries 0
            set -l max_location_tries 3
            while test "$use_ip" = false
                set -l prompt_str (set_color brwhite)"Enter location (city, postal code, or lat,lon e.g. 52.52,13.41) or press Enter to use IP: "(set_color normal)
                if test -z "$ip_line"; and test "$first_manual_prompt" = true
                    set prompt_str (set_color brwhite)"Could not detect location from IP. Enter location (city, postal code, or lat,lon e.g. 52.52,13.41) or press Enter to use IP: "(set_color normal)
                    set first_manual_prompt false
                end
                read -l -P "$prompt_str" reply
                set -l manual (string trim -- "$reply")
                if test -z "$manual"
                    set use_ip true
                    break
                end
                set -l resolved (__tide_report_validate_weather_location "$manual")
                set -l val_status $status
                set resolved (string trim -- $resolved)
                if test $val_status -eq 0
                    read -l -P (set_color brwhite)"Resolved to: $resolved. Use this location? [Y/n]: "(set_color normal) reply2
                    set -l r2 (string trim (string lower -- "$reply2"))
                    if test -z "$r2"; or test "$r2" = "y"; or test "$r2" = "yes"
                        if string match -qr '^-?[0-9]+\.?[0-9]*\s*,\s*-?[0-9]+\.?[0-9]*$' -- "$manual"
                            set -l parts (string split ',' -- "$manual")
                            set -U tide_report_weather_location (string trim -- $parts[1])","(string trim -- $parts[2])
                        else
                            set -U tide_report_weather_location "$manual"
                        end
                        set use_ip true
                        break
                    end
                else
                    echo (set_color red)"Location not found or weather unavailable. Try another."(set_color normal)
                    set location_tries (math $location_tries + 1)
                    if test $location_tries -ge $max_location_tries
                        echo (set_color bryellow)"Using IP-based location. You can set tide_report_weather_location later."(set_color normal)
                        set use_ip true
                        break
                    end
                end
            end
        end
        set -l left_add
        set -l right_add
        $add_github && set left_add github
        $add_weather && set right_add $right_add weather
        $add_moon && set right_add $right_add moon
        $add_tide && set right_add $right_add tide
        if test (count $left_add) -gt 0; or test (count $right_add) -gt 0
            _tide_report_apply_prompt_items "$left_add" "$right_add"
            set -l right_list
            $add_weather && set right_list $right_list weather
            $add_moon && set right_list $right_list moon
            $add_tide && set right_list $right_list tide
            set -l msg
            if $add_github
                set msg "Added: github (left)"
                if test (count $right_list) -gt 0
                    set msg "$msg, "(string join ", " $right_list)" (right)"
                end
            else
                set msg "Added: "(string join ", " $right_list)" (right)"
            end
            echo (set_color brwhite)"$msg."(set_color normal)
        end
        tide reload 2>/dev/null; or true
        echo (set_color brwhite)"Run "(set_color cyan)"tide reload"(set_color brwhite)" or start a new session to see your prompt."(set_color normal)
    end
end

## Handle Fisher update event: clear cache and re-run install logic.
function _tide_report_update --description "Handle fisher update: clear Tide Report cache and re-run install" --on-event tide_report_update
    command rm -rf ~/.cache/tide-report
    _tide_report_install
end

## Uninstall Tide Report: remove prompt items, variables, functions, and cache on Fisher uninstall.
function _tide_report_uninstall --description "Handle fisher uninstall: remove Tide Report items, vars, functions, and cache" --on-event tide_report_uninstall
    echo (set_color --bold brwhite)"Removing Tide Report Configuration & Cache..."(set_color normal)

    set -l tide_report_items github weather moon tide
    set -l new_right
    set -l new_left
    if set -q tide_right_prompt_items
        for item in $tide_right_prompt_items
            set -l keep true
            if contains -- $item $tide_report_items
                set keep false
            else
                for token in (string split " " -- $item)
                    if contains -- $token $tide_report_items
                        set keep false
                        break
                    end
                end
            end
            if $keep
                set -a new_right $item
            end
        end
        set -U tide_right_prompt_items $new_right
    end
    if set -q tide_left_prompt_items
        for item in $tide_left_prompt_items
            set -l keep true
            if contains -- $item $tide_report_items
                set keep false
            else
                for token in (string split " " -- $item)
                    if contains -- $token $tide_report_items
                        set keep false
                        break
                    end
                end
            end
            if $keep
                set -a new_left $item
            end
        end
        set -U tide_left_prompt_items $new_left
    end
    _tide_report_warn_global_prompt_items (string join " " $new_left) (string join " " $new_right)

    # Erase all universal variables we create. Intentionally leave tide_time_format (Tide core).
    set -l vars_to_erase (set -U --names | string match -r '^_*(tide_report|tide_github|tide_weather|tide_moon|tide_tide).*')
    for v in $vars_to_erase
        set -U -e $v
    end

    # Erase our functions (init handlers, item entry points, helpers)
    builtin functions --erase (builtin functions --all | string match --entire -r '^_*tide_report')

    # Remove cache
    command rm -rf ~/.cache/tide-report

    tide reload 2>/dev/null; or true
    echo (set_color brwhite)"Prompt refreshed. Run "(set_color cyan)"tide reload"(set_color brwhite)" or start a new session if items still appear."(set_color normal)
end

## Apply chosen Tide Report items to Tide prompt lists (insertion rules: github after git/pwd, right items appended).
function _tide_report_apply_prompt_items --description "Add selected Tide Report items to left/right prompt lists" --argument-names left_add right_add
    set -q tide_left_prompt_items || return 0
    set -q tide_right_prompt_items || return 0
    set -l left $tide_left_prompt_items
    set -l right $tide_right_prompt_items
    set -l left_items (string split " " -- (string trim -- "$left_add"))
    set -l right_items (string split " " -- (string trim -- "$right_add"))

    set -l new_left $left
    for item in $left_items
        test -z "$item" && continue
        if not contains -- $item $new_left
            if test "$item" = "github"
                if contains -- git $left
                    set -l out
                    for i in $new_left
                        set -a out $i
                        if test "$i" = "git"
                            set -a out github
                        end
                    end
                    set new_left $out
                else if contains -- pwd $left
                    set -l out
                    for i in $new_left
                        if test "$i" = "pwd"
                            set -a out github
                        end
                        set -a out $i
                    end
                    set new_left $out
                else
                    set new_left $new_left github
                end
            end
        end
    end

    set -l new_right $right
    for item in $right_items
        test -z "$item" && continue
        if not contains -- $item $new_right
            set new_right $new_right $item
        end
    end

    set -U tide_left_prompt_items $new_left
    set -U tide_right_prompt_items $new_right
    _tide_report_warn_global_prompt_items (string join " " $new_left) (string join " " $new_right)
end

## Add default Tide Report items when none are present (used when not interactive or when wizard is skipped).
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
    _tide_report_apply_prompt_items github "weather moon"
    if test "$silent" != "1"
        echo (set_color brwhite)"Tide Report: added prompt items. Run "(set_color cyan)"tide reload"(set_color brwhite)" if they don't appear."(set_color normal)
    end
end

## User-callable helper to run install logic manually (e.g. when Fisher event does not fire).
function tide_report_install --description "Run Tide Report install manually: add prompt items and set config"
    _tide_report_install
end
