## TideReport :: Prompt mutation and preview helpers

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

    set -l temp_sample "+22°"
    set -l feels_sample "+21°"
    set -l wind_sample "12km/h"
    if set -q tide_report_units; and test "$tide_report_units" = "u"
        set temp_sample "+72°"
        set feels_sample "+71°"
        set wind_sample "7mph"
    end

    if test "$which_item" = "all"
        set -l gh_out (__tide_report_render_github 86 75 30 9 42 pass | string collect)
        set -l w_fmt "%c %t %d%w"
        test "$weather_format" = "concise" && set w_fmt "%c %t"
        test "$weather_format" = "detailed" && set w_fmt "%c 🌡️%t (%f) %h %d%w"
        set -l save_fmt $tide_report_weather_format
        set -g tide_report_weather_format $w_fmt
        set -l weather_out (__tide_report_render_weather "$temp_sample" "$feels_sample" "☀️" "Clear" "$wind_sample" "⬇" "65%" "" "" "" | string collect)
        set -g tide_report_weather_format $save_fmt
        set -l moon_out (__tide_report_get_moon_emoji "Full Moon")
        set -l tide_out (__tide_report_render_tide H "14:30" 3.2 true | string collect)

        set -l left_part (set_color $tide_time_color -b $tide_github_bg_color)" … "
        if test -n "$sep_color"
            set left_part "$left_part"(set_color $sep_color -b $tide_github_bg_color)"$lsep "
        else
            set left_part "$left_part"(set_color normal -b $tide_github_bg_color)"$lsep "
        end
        set left_part "$left_part"(set_color $tide_github_color -b $tide_github_bg_color)" $gh_out "(set_color normal)
        if test -n "$left_suffix"
            set left_part "$left_part"(set_color $tide_github_bg_color -b 000000)"$left_suffix"
            set left_part "$left_part"(set_color normal)
        end

        set -l mid (set_color $conn_color)(string repeat -n 6 -- "$conn_icon")(set_color normal)

        set -l right_parts ""
        if test -n "$right_prefix"
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
            set -l out (__tide_report_render_github 86 75 30 9 42 pass | string collect)
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
