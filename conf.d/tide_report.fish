## TideReport :: Default Configuration

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

## Show sample render of prompt item(s) for install wizard. which_item: github|weather|moon|tide|all. weather_format: concise|medium|detailed (for weather/all).
## Uses render functions from item files; wraps each segment in Tide bg color and user-configured separators/suffix/prefix/connection.
function _tide_report_install_show_preview --description "Echo sample output for one item or all items with separators" --argument-names which_item weather_format default_bg_color
    set -q which_item || set which_item all
    set -q weather_format || set weather_format medium
    set -q default_bg_color || set default_bg_color (set -q tide_time_bg_color && echo $tide_time_bg_color || echo "normal")

    set -q tide_github_bg_color || set -l tide_github_bg_color $default_bg_color
    set -q tide_weather_bg_color || set -l tide_weather_bg_color $default_bg_color
    set -q tide_moon_bg_color || set -l tide_moon_bg_color $default_bg_color
    set -q tide_tide_bg_color || set -l tide_tide_bg_color $default_bg_color
    set -q tide_time_color || set -l tide_time_color grey
    set -q tide_github_color || set -l tide_github_color $tide_time_color
    set -q tide_weather_color || set -l tide_weather_color $tide_time_color
    set -q tide_moon_color || set -l tide_moon_color $tide_time_color
    set -q tide_tide_color || set -l tide_tide_color $tide_time_color

    set -q tide_left_prompt_separator_same_color || set -l tide_left_prompt_separator_same_color ""
    set -q tide_left_prompt_separator_diff_color || set -l tide_left_prompt_separator_diff_color ""
    set -q tide_left_prompt_suffix || set -l tide_left_prompt_suffix ""
    set -q tide_right_prompt_prefix || set -l tide_right_prompt_prefix ""
    set -q tide_right_prompt_separator_same_color || set -l tide_right_prompt_separator_same_color ""
    set -q tide_right_prompt_separator_diff_color || set -l tide_right_prompt_separator_diff_color ""
    set -q tide_prompt_icon_connection || set -l tide_prompt_icon_connection ""
    set -q tide_prompt_color_frame_and_connection || set -l tide_prompt_color_frame_and_connection "normal"
    set -q tide_color_separator_same_color || set -l tide_color_separator_same_color ""

    set -l lsep "$tide_left_prompt_separator_same_color"
    test -z "$lsep" && set lsep "$tide_left_prompt_separator_diff_color"
    set -l left_suffix "$tide_left_prompt_suffix"
    set -l right_prefix "$tide_right_prompt_prefix"
    set -l rsep "$tide_right_prompt_separator_same_color"
    test -z "$rsep" && set rsep "$tide_right_prompt_separator_diff_color"
    test -z "$rsep" && set rsep " "
    set -l conn_icon "$tide_prompt_icon_connection"
    test -z "$conn_icon" && set conn_icon "─"
    set -l sep_color "$tide_color_separator_same_color"
    set -l conn_color "$tide_prompt_color_frame_and_connection"

    # Sample strings for weather preview by units (tide uses tide_report_units in render)
    set -l temp_sample "+22°"
    set -l feels_sample "+21°"
    set -l wind_sample "12km/h"
    if set -q tide_report_units; and test "$tide_report_units" = "u"
        set temp_sample "+72°"
        set feels_sample "+71°"
        set wind_sample "7mph"
    end

    if test "$which_item" = "all"
        set -l gh_out (__tide_report_render_github 42 3 7 2 5 pass | string collect)
        set -l w_fmt "%c %t %d%w"
        test "$weather_format" = "concise" && set w_fmt "%c %t"
        test "$weather_format" = "detailed" && set w_fmt "%c 🌡️%t (%f) %h %d%w"
        set -l save_fmt $tide_report_weather_format
        set -g tide_report_weather_format $w_fmt
        set -l weather_out (__tide_report_render_weather "$temp_sample" "$feels_sample" "☀️" "Clear" "$wind_sample" "⬇" "65%" "" "" "" | string collect)
        set -g tide_report_weather_format $save_fmt
        set -l moon_out (__tide_report_get_moon_emoji "Full Moon")
        set -l tide_out (__tide_report_render_tide H "14:30" 3.2 true | string collect)

        # Left: … (prompt bg, default fg) + space + left_sep + space + GitHub sample + left_suffix (prompt bg, fg black)
        set -l left_part (set_color $tide_time_color -b $tide_github_bg_color)" … "
        if test -n "$sep_color"
            set left_part "$left_part"(set_color $sep_color -b $tide_github_bg_color)"$lsep "
        else
            set left_part "$left_part"(set_color normal -b $tide_github_bg_color)"$lsep "
        end
        set left_part "$left_part"(set_color $tide_github_color -b $tide_github_bg_color)" $gh_out "(set_color normal)
        if test -n "$left_suffix"
            # Suffix: black bg, fg = prompt segment bg. Set both in one call: fg first, then -b for bg.
            set left_part "$left_part"(set_color $tide_github_bg_color -b 000000)"$left_suffix"
            set left_part "$left_part"(set_color normal)
        end

        # Middle: 6 × connection icon (no spaces; icon replaces the gaps on either side)
        set -l mid (set_color $conn_color)(string repeat -n 6 -- "$conn_icon")(set_color normal)

        # Right: right_prefix (first item bg, fg black) + … (prompt bg, default fg) + space + right_sep + weather/moon/tide (each with item fg)
        set -l right_parts ""
        if test -n "$right_prefix"
            # Prefix: black bg, fg = first right segment bg.
            set right_parts "$right_parts"(set_color $tide_weather_bg_color -b 000000)"$right_prefix"
        end
        set right_parts "$right_parts"(set_color $tide_time_color -b $tide_weather_bg_color)" … "
        if test -n "$sep_color"
            set right_parts "$right_parts"(set_color $sep_color -b $tide_weather_bg_color)"$rsep "
        else
            set right_parts "$right_parts"(set_color normal -b $tide_weather_bg_color)"$rsep "
        end
        set right_parts "$right_parts"(set_color $tide_weather_color -b $tide_weather_bg_color)"$weather_out"
        if test -n "$sep_color"
            set right_parts "$right_parts"(set_color $sep_color -b $tide_weather_bg_color)" $rsep "
        else
            set right_parts "$right_parts"(set_color normal -b $tide_weather_bg_color)" $rsep "
        end
        set right_parts "$right_parts"(set_color $tide_moon_color -b $tide_moon_bg_color)"$moon_out"
        if test -n "$sep_color"
            set right_parts "$right_parts"(set_color $sep_color -b $tide_moon_bg_color)" $rsep "
        else
            set right_parts "$right_parts"(set_color normal -b $tide_moon_bg_color)" $rsep "
        end
        set right_parts "$right_parts"(set_color $tide_tide_color -b $tide_tide_bg_color)"$tide_out"(set_color normal)

        echo (set_color brwhite)"$left_part$mid$right_parts"(set_color normal)
        return
    end

    switch "$which_item"
        case github
            set -l out (__tide_report_render_github 42 3 7 2 5 pass | string collect)
            set -l line (set_color $tide_time_color -b $tide_github_bg_color)" … "
            if test -n "$sep_color"
                set line "$line"(set_color $sep_color -b $tide_github_bg_color)"$lsep "
            else
                set line "$line"(set_color normal -b $tide_github_bg_color)"$lsep "
            end
            set line "$line"(set_color $tide_github_color -b $tide_github_bg_color)" $out "
            if test -n "$left_suffix"
                set line "$line"(set_color $tide_github_bg_color -b 000000)"$left_suffix"
            end
            echo (set_color brwhite)"$line"(set_color normal)
        case weather
            set -l w_fmt "%c %t %d%w"
            test "$weather_format" = "concise" && set w_fmt "%c %t"
            test "$weather_format" = "detailed" && set w_fmt "%c 🌡️%t (%f) %h %d%w"
            set -l save_fmt $tide_report_weather_format
            set -g tide_report_weather_format $w_fmt
            set -l out (__tide_report_render_weather "$temp_sample" "$feels_sample" "☀️" "Clear" "$wind_sample" "⬇" "65%" "" "" "" | string collect)
            set -g tide_report_weather_format $save_fmt
            set -l line ""
            if test -n "$right_prefix"
                set line (set_color $tide_weather_bg_color -b 000000)"$right_prefix"
            end
            set line "$line"(set_color $tide_time_color -b $tide_weather_bg_color)" … "
            if test -n "$sep_color"
                set line "$line"(set_color $sep_color -b $tide_weather_bg_color)" $rsep "
            else
                set line "$line"(set_color normal -b $tide_weather_bg_color)" $rsep "
            end
            set line "$line"(set_color $tide_weather_color -b $tide_weather_bg_color)"$out"(set_color normal)
            echo (set_color brwhite)"$line"(set_color normal)
        case moon
            set -l out (__tide_report_get_moon_emoji "Full Moon")
            set -l line ""
            if test -n "$right_prefix"
                set line (set_color $tide_moon_bg_color -b 000000)"$right_prefix"
            end
            set line "$line"(set_color $tide_time_color -b $tide_moon_bg_color)" … "
            if test -n "$sep_color"
                set line "$line"(set_color $sep_color -b $tide_moon_bg_color)" $rsep "
            else
                set line "$line"(set_color normal -b $tide_moon_bg_color)" $rsep "
            end
            set line "$line"(set_color $tide_moon_color -b $tide_moon_bg_color)" $out "(set_color normal)
            echo (set_color brwhite)"$line"(set_color normal)
        case tide
            set -l out (__tide_report_render_tide H "14:30" 3.2 true | string collect)
            set -l line ""
            if test -n "$right_prefix"
                set line (set_color $tide_tide_bg_color -b 000000)"$right_prefix"
            end
            set line "$line"(set_color $tide_time_color -b $tide_tide_bg_color)" … "
            if test -n "$sep_color"
                set line "$line"(set_color $sep_color -b $tide_tide_bg_color)" $rsep "
            else
                set line "$line"(set_color normal -b $tide_tide_bg_color)" $rsep "
            end
            set line "$line"(set_color $tide_tide_color -b $tide_tide_bg_color)" $out "(set_color normal)
            echo (set_color brwhite)"$line"(set_color normal)
    end
end

## Install TideReport defaults and register prompt items on Fisher install event.
function _tide_report_install --description "Install TideReport defaults and prompt items on fisher event" --on-event tide_report_install
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

    echo (set_color --bold brwhite)"Installing TideReport v$_tide_report_version..."(set_color normal)

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
    set -q tide_report_weather_unavailable_text    || set -U tide_report_weather_unavailable_text "…"
    set -q tide_report_weather_unavailable_color   || set -U tide_report_weather_unavailable_color red

    set -q tide_moon_color                    || set -U tide_moon_color $default_color
    set -q tide_moon_bg_color                 || set -U tide_moon_bg_color $default_bg_color
    set -q tide_report_moon_provider          || set -U tide_report_moon_provider "local"
    set -q tide_report_moon_refresh_seconds   || set -U tide_report_moon_refresh_seconds 14400
    set -q tide_report_moon_expire_seconds    || set -U tide_report_moon_expire_seconds 28800
    set -q tide_report_moon_unavailable_text  || set -U tide_report_moon_unavailable_text "…"
    set -q tide_report_moon_unavailable_color || set -U tide_report_moon_unavailable_color red

    set -q tide_tide_color                    || set -U tide_tide_color 0087AF
    set -q tide_tide_bg_color                 || set -U tide_tide_bg_color $default_bg_color
    set -q tide_report_tide_station_id        || set -U tide_report_tide_station_id "8443970"
    set -q tide_report_tide_refresh_seconds   || set -U tide_report_tide_refresh_seconds 14400
    set -q tide_report_tide_expire_seconds    || set -U tide_report_tide_expire_seconds 28800
    set -q tide_report_tide_symbol_high       || set -U tide_report_tide_symbol_high "⇞"
    set -q tide_report_tide_symbol_low        || set -U tide_report_tide_symbol_low "⇟"
    set -q tide_report_tide_symbol_color      || set -U tide_report_tide_symbol_color white
    set -q tide_report_tide_unavailable_text  || set -U tide_report_tide_unavailable_text "🌊…"
    set -q tide_report_tide_unavailable_color || set -U tide_report_tide_unavailable_color red
    set -q tide_report_tide_show_level        || set -U tide_report_tide_show_level "true"

    set -q tide_github_color                       || set -U tide_github_color white
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
    set -q tide_report_github_unavailable_text     || set -U tide_report_github_unavailable_text "…"
    set -q tide_report_github_unavailable_color    || set -U tide_report_github_unavailable_color red
    set -q tide_report_github_refresh_seconds      || set -U tide_report_github_refresh_seconds 30
    set -q tide_report_github_show_ci              || set -U tide_report_github_show_ci true
    set -q tide_report_github_icon_ci_pass         || set -U tide_report_github_icon_ci_pass "✔"
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
        type -q tide && tide reload 2>/dev/null; or true
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
        echo (set_color brwhite)"TideReport prompt items already present; leaving your prompt configuration unchanged."(set_color normal)
        type -q tide && tide reload 2>/dev/null; or true
    else if not status is-interactive
        _tide_report_ensure_prompt_items 1
        type -q tide && tide reload 2>/dev/null; or true
        echo (set_color brwhite)"TideReport: added github (left), weather, moon (right). Run "(set_color cyan)"'tide reload'"(set_color brwhite)" if they don't appear."(set_color normal)
    else
        echo ""
        echo (set_color brcyan)"────────────────[ "(set_color brwhite)"Units"(set_color brcyan)" ]────────────────"(set_color normal)
        echo (set_color brwhite)"  Use metric or US?"(set_color normal)
        echo (set_color brcyan)"    1"(set_color brwhite)") Metric (°C, km/h, m)"(set_color normal)
        echo (set_color brcyan)"    2"(set_color brwhite)") Freedom Units (°F, mph, ft)"(set_color normal)
        echo ""
        read -l -P (set_color brcyan)"1=metric 2=US "(set_color brgreen)"["(set_color bryellow)"1"(set_color brgreen)"]"(set_color brcyan)": "(set_color normal) units_choice
        set -l units "1"
        if test -n "$units_choice"
            string match -q -r '^[12]$' -- $units_choice && set units $units_choice
        end
        if test "$units" = "2"
            set -U tide_report_units "u"
        else
            set -U tide_report_units "m"
        end
        echo ""
        echo (set_color --bold brwhite)"TideReport Prompt Items:"(set_color normal)
        echo (set_color brwhite)"Choose which items to add to your prompt."(set_color normal)
        echo ""
        echo (set_color brwhite)"Preview:"(set_color normal)
        _tide_report_install_show_preview all medium $default_bg_color
        echo ""

        echo (set_color brcyan)"────────────────[ "(set_color brwhite)"GitHub"(set_color brcyan)" ]────────────────"(set_color normal)
        _tide_report_install_show_preview github "" $default_bg_color
        echo ""
        set -l add_github false
        read -l -P (set_color brcyan)"Add GitHub to prompt? "(set_color brgreen)"["(set_color bryellow)"Y"(set_color brgreen)"/"(set_color bryellow)"n"(set_color brgreen)"]"(set_color brcyan)": "(set_color normal) reply
        set -l r (string trim (string lower -- "$reply"))
        if test -z "$r"; or test "$r" = "y"; or test "$r" = "yes"
            set add_github true
        end
        if $add_github
            read -l -P (set_color brcyan)"Show CI status in GitHub item? "(set_color brgreen)"["(set_color bryellow)"Y"(set_color brgreen)"/"(set_color bryellow)"n"(set_color brgreen)"]"(set_color brcyan)": "(set_color normal) reply
            set -l r (string trim (string lower -- "$reply"))
            if test -z "$r"; or test "$r" = "y"; or test "$r" = "yes"
                set -U tide_report_github_show_ci true
            else if test "$r" = "n"; or test "$r" = "no"
                set -U tide_report_github_show_ci false
            end
        end

        echo (set_color brcyan)"────────────────[ "(set_color brwhite)"Weather"(set_color brcyan)" ]───────────────"(set_color normal)
        echo (set_color brwhite)"  Weather format samples:"(set_color normal)
        echo (set_color brcyan)"    1"(set_color brwhite)") Concise  "(set_color normal); _tide_report_install_show_preview weather concise $default_bg_color
        echo (set_color brcyan)"    2"(set_color brwhite)") Medium   "(set_color normal); _tide_report_install_show_preview weather medium $default_bg_color
        echo (set_color brcyan)"    3"(set_color brwhite)") Detailed "(set_color normal); _tide_report_install_show_preview weather detailed $default_bg_color
        echo ""

        set -l add_weather false
        read -l -P (set_color brcyan)"Add Weather to prompt? "(set_color brgreen)"["(set_color bryellow)"Y"(set_color brgreen)"/"(set_color bryellow)"n"(set_color brgreen)"]"(set_color brcyan)": "(set_color normal) reply
        set -l r (string trim (string lower -- "$reply"))
        if test -z "$r"; or test "$r" = "y"; or test "$r" = "yes"
            set add_weather true
        end
        if $add_weather
            read -l -P (set_color brcyan)"Weather format? "(set_color cyan)"1"(set_color brwhite)"=concise "(set_color cyan)"2"(set_color brwhite)"=medium "(set_color cyan)"3"(set_color brwhite)"=detailed "(set_color brgreen)"["(set_color bryellow)"2"(set_color brgreen)"]"(set_color brcyan)": "(set_color normal) format_choice
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
                echo (set_color brcyan)"Retrieving location..."(set_color normal)
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
                read -l -P (set_color brcyan)"Detected location: "(set_color brwhite)"$ip_line"(set_color brcyan)". Use this location? "(set_color brgreen)"["(set_color bryellow)"Y"(set_color brgreen)"/"(set_color bryellow)"n"(set_color brgreen)"]"(set_color brcyan)": "(set_color normal) reply
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
                set -l prompt_str (set_color brcyan)"Enter location "(set_color brwhite)"(city, postal code, or lat,lon e.g. 52.52,13.41)"(set_color brcyan)" or press Enter to use IP: "(set_color normal)
                if test -z "$ip_line"; and test "$first_manual_prompt" = true
                    set prompt_str (set_color brcyan)"Could not detect location from IP. Enter location "(set_color brwhite)"(city, postal code, or lat,lon e.g. 52.52,13.41)"(set_color brcyan)" or press Enter to use IP: "(set_color normal)
                    set first_manual_prompt false
                end
                read -l -P "$prompt_str" reply
                set -l manual (string trim -- "$reply")
                if test -z "$manual"
                    set use_ip true
                    break
                end
                echo (set_color brcyan)"Retrieving location..."(set_color normal)
                set -l resolved (__tide_report_validate_weather_location "$manual")
                set -l val_status $status
                set resolved (string trim -- $resolved)
                    if test $val_status -eq 0
                        read -l -P (set_color brcyan)"Resolved to: "(set_color brwhite)"$resolved"(set_color brcyan)". Use this location? "(set_color brgreen)"["(set_color bryellow)"Y"(set_color brgreen)"/"(set_color bryellow)"n"(set_color brgreen)"]"(set_color brcyan)": "(set_color normal) reply2
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

        echo (set_color brcyan)"────────────────[ "(set_color brwhite)"Moon"(set_color brcyan)" ]────────────────"(set_color normal)
        _tide_report_install_show_preview moon "" $default_bg_color
        echo ""
        set -l add_moon false
        read -l -P (set_color brcyan)"Add Moon to prompt? "(set_color brgreen)"["(set_color bryellow)"Y"(set_color brgreen)"/"(set_color bryellow)"n"(set_color brgreen)"]"(set_color brcyan)": "(set_color normal) reply
        set -l r (string trim (string lower -- "$reply"))
        if test -z "$r"; or test "$r" = "y"; or test "$r" = "yes"
            set add_moon true
        end

        echo (set_color brcyan)"────────────────[ "(set_color brwhite)"Tide"(set_color brcyan)" ]────────────────"(set_color normal)
        _tide_report_install_show_preview tide "" $default_bg_color
        echo ""
        set -l add_tide false
        read -l -P (set_color brcyan)"Add Tide to prompt? "(set_color brgreen)"["(set_color bryellow)"y"(set_color brgreen)"/"(set_color bryellow)"N"(set_color brgreen)"]"(set_color brcyan)": "(set_color normal) reply
        set -l r (string trim (string lower -- "$reply"))
        if test -n "$r"; and test "$r" != "n"; and test "$r" != "no"
            if test "$r" = "y"; or test "$r" = "yes"
                set add_tide true
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
        type -q tide && tide reload 2>/dev/null; or true
        echo (set_color brwhite)"You may need to run "(set_color cyan)"'tide reload'"(set_color brwhite)" or start a new session to see your prompt."(set_color normal)
    end
end

## Handle Fisher update event: clear cache and re-run install logic.
function _tide_report_update --description "Handle fisher update: clear TideReport cache and re-run install" --on-event tide_report_update
    command rm -rf ~/.cache/tide-report
    _tide_report_install
end

## Uninstall TideReport: remove prompt items, variables, functions, and cache on Fisher uninstall.
function _tide_report_uninstall --description "Handle fisher uninstall: remove TideReport items, vars, functions, and cache" --on-event tide_report_uninstall
    echo (set_color --bold brwhite)"Removing TideReport Configuration & Cache..."(set_color normal)

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

    type -q tide && tide reload 2>/dev/null; or true
    echo (set_color brwhite)"Prompt refreshed. Run "(set_color cyan)"'tide reload'"(set_color brwhite)" or start a new session if items still appear."(set_color normal)
end

## Apply chosen TideReport items to Tide prompt lists (insertion rules: github after git/pwd, right items appended).
function _tide_report_apply_prompt_items --description "Add selected TideReport items to left/right prompt lists" --argument-names left_add right_add
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

## Add default TideReport items when none are present (used when not interactive or when wizard is skipped).
function _tide_report_ensure_prompt_items --description "Ensure TideReport items exist in Tide prompt lists" --argument-names silent
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
        echo (set_color brwhite)"TideReport: added prompt items. Run "(set_color cyan)"'tide reload'"(set_color brwhite)" if they don't appear."(set_color normal)
    end
end

## User-callable helper to run install logic manually (e.g. when Fisher event does not fire).
function tide_report_install --description "Run TideReport install manually: add prompt items and set config"
    _tide_report_install
end
