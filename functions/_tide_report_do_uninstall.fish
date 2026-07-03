function _tide_report_do_uninstall --description "Remove TideReport items, vars, functions, and cache (called by uninstall event)"
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
    if not functions -q _tide_report_warn_global_prompt_items
        source (status filename | path dirname)/_tide_report_prompt_helpers.fish
    end
    _tide_report_warn_global_prompt_items (string join " " $new_left) (string join " " $new_right)

    # Reload Tide while our item functions still exist so $_tide_*_items match updated universals.
    if type -q tide
        tide reload 2>/dev/null
    else if functions -q _tide_remove_unusable_items
        _tide_remove_unusable_items
    end

    # Erase all universal variables we create. Intentionally leave tide_time_format (Tide core).
    set -l vars_to_erase (set -U --names | string match -r '^_*(tide_report|tide_github|tide_weather|tide_moon|tide_tide).*')
    for v in $vars_to_erase
        set -U -e $v
    end

    # Erase our functions (init handlers, item entry points, helpers).
    # Do not pipe to `string match -r`: capture groups emit spurious names (e.g. `tide` from `_tide_item_tide`).
    set -l tide_report_funcs
    set -l tide_report_func_pattern '^(_*tide_report|_tide_item_(github|weather|moon|tide))'
    for f in (builtin functions --all)
        string match -q --entire -r $tide_report_func_pattern -- $f
        and set -a tide_report_funcs $f
    end
    if test (count $tide_report_funcs) -gt 0
        builtin functions --erase $tide_report_funcs
    end

    # Remove cache
    command rm -rf ~/.cache/tide-report
    echo (set_color brwhite)"Prompt refreshed. Run "(set_color cyan)"'tide reload'"(set_color brwhite)" or start a new session if items still appear."(set_color normal)
end
