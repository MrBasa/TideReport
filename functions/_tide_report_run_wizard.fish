function _tide_report_run_wizard --description "Interactive TideReport configuration wizard" --argument-names default_color default_bg_color
    if not functions -q _tide_report_install_show_preview
        source (status dirname)/_tide_report_prompt_helpers.fish
    end

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
            case 3; set -U tide_report_weather_format "%c %t (%f) %h %d%w"
            case "*"; set -U tide_report_weather_format "%c %t %d%w"
        end
        echo (set_color brwhite)"  Weather location modes:"(set_color normal)
        echo (set_color brcyan)"    IP-based auto-detect"(set_color brwhite)" follows your current network/location and may change over time."(set_color normal)
        echo (set_color brcyan)"    Fixed location"(set_color brwhite)" saves a city, postal code, or coordinates so weather stays pinned to one place."(set_color normal)
        set -l ip_line ""
        if command -q curl; and command -q jq
            if not functions -q __tide_report_openmeteo_wizard_ip_line
                source (status filename | path dirname)/_tide_report_weather_helpers.fish
            end
            echo (set_color brcyan)"Retrieving location..."(set_color normal)
            set ip_line (__tide_report_openmeteo_wizard_ip_line 5)
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
            set -l resolved (_tide_report_validate_weather_location "$manual")
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
    echo (set_color brwhite)"To reconfigure TideReport later, run "(set_color cyan)"tide-report configure"(set_color brwhite)" or "(set_color cyan)"fisher update MrBasa/TideReport@v1"(set_color brwhite)" and answer yes at the wizard prompt."(set_color normal)

    if not functions -q _tide_report_run_health_checks
        source (status filename | path dirname)/_tide_report_health_checks.fish
    end
    _tide_report_run_health_checks
end
