source (status filename | path dirname)/_tide_report_defaults.fish
source (status filename | path dirname)/_tide_report_prompt_helpers.fish

function _tide_report_do_install --description "Install TideReport defaults and prompt items (called by install event)"
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
        read -l -P (set_color brcyan)"Run the TideReport install wizard? "(set_color brgreen)"["(set_color bryellow)"Y"(set_color brgreen)"/"(set_color bryellow)"n"(set_color brgreen)"]"(set_color brcyan)": "(set_color normal) wizard_reply
        set -l r (string trim (string lower -- "$wizard_reply"))
        set -l run_wizard true
        if test "$r" = "n"; or test "$r" = "no"
            set run_wizard false
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
        echo (set_color brcyan)"────[ "(set_color -o brwhite)"TideReport Installation Wizard"(set_color normal && set_color brcyan)" ]────"(set_color normal)
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
        echo (set_color brwhite)"Choose which items to add to your prompt."(set_color normal)
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
            ## Location step: explain IP-based auto-detection vs a saved fixed location.
            echo (set_color brwhite)"  Weather location modes:"(set_color normal)
            echo (set_color brcyan)"    IP-based auto-detect"(set_color brwhite)" follows your current network/location and may change over time."(set_color normal)
            echo (set_color brcyan)"    Fixed location"(set_color brwhite)" saves a city, postal code, or coordinates so weather stays pinned to one place."(set_color normal)
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
            set -l use_ip_location true
            if test -n "$ip_line"
                echo (set_color brwhite)"  Choosing IP-based auto-detect keeps tide_report_weather_location empty, so weather follows your current IP-based location."(set_color normal)
                read -l -P (set_color brcyan)"Detected IP-based location: "(set_color brwhite)"$ip_line"(set_color brcyan)". Use IP-based auto-detect for weather? "(set_color brgreen)"["(set_color bryellow)"Y"(set_color brgreen)"/"(set_color bryellow)"n"(set_color brgreen)"]"(set_color brcyan)": "(set_color normal) reply
                set -l r (string trim (string lower -- "$reply"))
                if test "$r" = "n"; or test "$r" = "no"
                    set use_ip_location false
                else
                    set -U tide_report_weather_location ""
                end
            else
                set use_ip_location false
            end
            set -l first_manual_prompt true
            set -l location_tries 0
            set -l max_location_tries 3
            while test "$use_ip_location" = false
                set -l prompt_str (set_color brcyan)"Enter a fixed location "(set_color brwhite)"(city, postal code, or lat,lon e.g. 52.52,13.41)"(set_color brcyan)" or press Enter to keep IP-based auto-detect: "(set_color normal)
                if test -z "$ip_line"; and test "$first_manual_prompt" = true
                    set prompt_str (set_color brcyan)"Could not detect an IP-based location right now. Enter a fixed location "(set_color brwhite)"(city, postal code, or lat,lon e.g. 52.52,13.41)"(set_color brcyan)" or press Enter to keep IP-based auto-detect: "(set_color normal)
                    set first_manual_prompt false
                end
                read -l -P "$prompt_str" reply
                set -l manual (string trim -- "$reply")
                if test -z "$manual"
                    set -U tide_report_weather_location ""
                    set use_ip_location true
                    break
                end
                echo (set_color brcyan)"Retrieving location..."(set_color normal)
                set -l resolved (__tide_report_validate_weather_location "$manual")
                set -l val_status $status
                set resolved (string trim -- $resolved)
                if test $val_status -eq 0
                    echo (set_color brwhite)"  Saving a fixed location writes tide_report_weather_location so weather stays pinned to this place."(set_color normal)
                    read -l -P (set_color brcyan)"Resolved fixed location: "(set_color brwhite)"$resolved"(set_color brcyan)". Save this fixed location? "(set_color brgreen)"["(set_color bryellow)"Y"(set_color brgreen)"/"(set_color bryellow)"n"(set_color brgreen)"]"(set_color brcyan)": "(set_color normal) reply2
                    set -l r2 (string trim (string lower -- "$reply2"))
                    if test -z "$r2"; or test "$r2" = "y"; or test "$r2" = "yes"
                        if string match -qr '^-?[0-9]+\.?[0-9]*\s*,\s*-?[0-9]+\.?[0-9]*$' -- "$manual"
                            set -l parts (string split ',' -- "$manual")
                            set -U tide_report_weather_location (string trim -- $parts[1])","(string trim -- $parts[2])
                        else
                            set -U tide_report_weather_location "$manual"
                        end
                        set use_ip_location true
                        break
                    end
                else
                    echo (set_color red)"Location not found or weather unavailable. Try another."(set_color normal)
                    set location_tries (math $location_tries + 1)
                    if test $location_tries -ge $max_location_tries
                        echo (set_color bryellow)"Using IP-based auto-detection. You can set tide_report_weather_location later to pin a fixed location."(set_color normal)
                        set -U tide_report_weather_location ""
                        set use_ip_location true
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
        echo (set_color brwhite)"To reconfigure TideReport later, run '"(set_color cyan)"fisher update MrBasa/TideReport@v1"(set_color brwhite)"' and choose to run the wizard."(set_color normal)
        end
    end
end
