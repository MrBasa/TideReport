function _tide_report_do_install --description "Install TideReport defaults and prompt items (called by install event)" --argument-names context
    set -q context[1]; or set context install

    if not functions -q __tide_report_apply_defaults
        source (status filename | path dirname)/_tide_report_defaults.fish
    end
    if not functions -q _tide_report_install_show_preview
        source (status filename | path dirname)/_tide_report_prompt_helpers.fish
    end

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
    end

    echo (set_color --bold brwhite)"Installing TideReport v$_tide_report_version..."(set_color normal)

    ## --- Check dependencies ---
    if ! command -v "gh" 2>/dev/null >/dev/null
        echo (set_color bryellow)"WARNING: Required dependency 'gh' (GitHub CLI) is not installed. Required for github prompt item."(set_color normal)
        functions -q _tide_report_log_expected && _tide_report_log_expected dependency "gh not installed"
    end
    if ! command -v "jq" 2>/dev/null >/dev/null
        echo (set_color bryellow)"WARNING: Required dependency 'jq' is not installed. Required for github, tide, weather, and moon items."(set_color normal)
        functions -q _tide_report_log_expected && _tide_report_log_expected dependency "jq not installed"
    end
    if ! command -v "curl" 2>/dev/null >/dev/null
        echo (set_color bryellow)"WARNING: Required dependency 'curl' is not installed. Required for weather, moon, and tide prompt items."(set_color normal)
        functions -q _tide_report_log_expected && _tide_report_log_expected dependency "curl not installed"
    end

    set -U tide_report_user_agent "tide-report/$_tide_report_version"
    __tide_report_apply_defaults U "$default_color" "$default_bg_color"

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

    if not status is-interactive
        if $any_present
            echo (set_color brwhite)"TideReport prompt items already present; leaving your prompt configuration unchanged."(set_color normal)
            type -q tide && tide reload 2>/dev/null; or true
        else
            _tide_report_ensure_prompt_items 1
            type -q tide && tide reload 2>/dev/null; or true
            echo (set_color brwhite)"TideReport: added github (left), weather, moon (right). Run "(set_color cyan)"'tide reload'"(set_color brwhite)" if they don't appear."(set_color normal)
        end
    else
        set -l run_wizard false
        if test "$context" = update
            read -l -P (set_color brcyan)"Run the TideReport configuration wizard? "(set_color brgreen)"["(set_color bryellow)"y"(set_color brgreen)"/"(set_color bryellow)"N"(set_color brgreen)"]"(set_color brcyan)": "(set_color normal) wizard_reply
            set -l r (string trim (string lower -- "$wizard_reply"))
            if test -n "$r"; and test "$r" != "n"; and test "$r" != "no"
                if test "$r" = "y"; or test "$r" = "yes"
                    set run_wizard true
                end
            end
        else
            read -l -P (set_color brcyan)"Run the TideReport install wizard? "(set_color brgreen)"["(set_color bryellow)"Y"(set_color brgreen)"/"(set_color bryellow)"n"(set_color brgreen)"]"(set_color brcyan)": "(set_color normal) wizard_reply
            set -l r (string trim (string lower -- "$wizard_reply"))
            set run_wizard true
            if test "$r" = "n"; or test "$r" = "no"
                set run_wizard false
            end
        end
        if not $run_wizard
            if $any_present
                echo (set_color brwhite)"TideReport prompt items already present; leaving your prompt configuration unchanged."(set_color normal)
                type -q tide && tide reload 2>/dev/null; or true
            else
                _tide_report_ensure_prompt_items 1
                type -q tide && tide reload 2>/dev/null; or true
                echo (set_color brwhite)"TideReport: added github (left), weather, moon (right). Run "(set_color cyan)"'tide reload'"(set_color brwhite)" if they don't appear."(set_color normal)
            end
        else
            _tide_report_run_wizard "$default_color" "$default_bg_color"
        end
    end
end
