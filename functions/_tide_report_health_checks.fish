## TideReport :: Configuration health checks (install, wizard, tide-report doctor)

function __tide_report_health_out --description "Write health line to stderr or stdout for bug-report" --argument-names stream text
    if test "$stream" = stdout
        echo "$text"
    else
        echo "$text" >&2
    end
end

function __tide_report_health_warn --description "Emit a warning line" --argument-names stream text
    set -l c_warn (set_color bryellow)
    set -l c_norm (set_color normal)
    __tide_report_health_out "$stream" "$c_warn""WARNING:$c_norm $text"
end

function __tide_report_health_info --description "Emit an informational line" --argument-names stream text
    set -l c_info (set_color brwhite)
    set -l c_norm (set_color normal)
    __tide_report_health_out "$stream" "$c_info""INFO:$c_norm $text"
end

function __tide_report_health_hint --description "Emit a fix hint line" --argument-names stream text
    set -l c_hint (set_color brwhite)
    set -l c_norm (set_color normal)
    __tide_report_health_out "$stream" "$c_hint$text$c_norm"
end

function __tide_report_health_cmd --description "Return whether a command exists (test hook: TIDE_REPORT_TEST_CMD_MISSING)" --argument-names name
    if set -q TIDE_REPORT_TEST_CMD_MISSING
        if contains -- "$name" $TIDE_REPORT_TEST_CMD_MISSING
            return 1
        end
    end
    command -v "$name" >/dev/null 2>&1
end

function __tide_report_health_fish_at_least --description "Return success when fish_version is at least major.minor" --argument-names major minor
    set -q fish_version; or return 1
    set -l parts (string match -r '^(\d+)\.(\d+)' -- $fish_version)
    test (count $parts) -ge 3; or return 1
    set -l have_major (math $parts[2])
    set -l have_minor (math $parts[3])
    if test $have_major -gt $major
        return 0
    end
    if test $have_major -eq $major; and test $have_minor -ge $minor
        return 0
    end
    return 1
end

function __tide_report_github_auth_ok_doctor --description "Fresh gh auth check (no session cache)"
    if set -q TIDE_REPORT_TEST_GH_AUTH_FAIL
        return 1
    end
    gh auth status -h github.com 2>/dev/null
end

function _tide_report_enabled_items --description "List TideReport prompt items enabled in Tide lists"
    set -l our_items github weather moon tide
    set -l enabled
    for item in $our_items
        set -l present false
        if set -q tide_left_prompt_items; and contains -- $item $tide_left_prompt_items
            set present true
        end
        if not $present; and set -q tide_right_prompt_items; and contains -- $item $tide_right_prompt_items
            set present true
        end
        $present; and set -a enabled $item
    end
    test (count $enabled) -gt 0; and printf "%s\n" $enabled
end

function _tide_report_health_prompt_list_reminders --description "Global prompt override warning and tide reload reminder" --argument-names stream
    set -q stream[1]; or set stream stderr
    set -l enabled (_tide_report_enabled_items)
    test (count $enabled) -gt 0; or return 0

    source (status filename | path dirname)/_tide_report_prompt_helpers.fish
    set -l left (set -q tide_left_prompt_items; and string join " " $tide_left_prompt_items; or echo "")
    set -l right (set -q tide_right_prompt_items; and string join " " $tide_right_prompt_items; or echo "")
    if set -q -g tide_left_prompt_items; or set -q -g tide_right_prompt_items
        __tide_report_health_warn "$stream" "tide_left_prompt_items and/or tide_right_prompt_items are set globally (e.g. in config.fish), which overrides universals."
    end
    set -l warn_out (_tide_report_warn_global_prompt_items "$left" "$right" 2>&1 | string collect)
    if test -n "$warn_out"
        __tide_report_health_out "$stream" "$warn_out"
    end
    set -l cw (set_color brwhite)
    set -l cc (set_color cyan)
    set -l cn (set_color normal)
    set -l reload_msg "$cw"After changing prompt items, run: "$cc"tide reload"$cn"
    __tide_report_health_out "$stream" "$reload_msg"
end

function __tide_report_health_check_dependencies --description "H-1: jq and curl for enabled items" --argument-names enabled stream quiet
    set -l need_jq false
    set -l need_curl false
    set -l curl_items
    for item in $enabled
        set need_jq true
        if contains -- $item weather tide
            set need_curl true
            set -a curl_items $item
        end
        if contains -- $item moon
            set -q tide_report_moon_provider; or set -l tide_report_moon_provider local
            if test "$tide_report_moon_provider" = wttr
                set need_curl true
                contains -- moon $curl_items; or set -a curl_items moon
            end
        end
    end

    if $need_jq; and not __tide_report_health_cmd jq
        set -l affected (string join ", " $enabled)
        __tide_report_health_warn "$stream" "jq is not installed (affects enabled items: $affected). The prompt will not block, but data stays unavailable."
        __tide_report_health_hint "$stream" "Install jq (see README Requirements)."
    end

    if $need_curl; and not __tide_report_health_cmd curl
        set -l affected (string join ", " $curl_items)
        __tide_report_health_warn "$stream" "curl is not installed (affects: $affected). The prompt will not block, but data stays unavailable."
        __tide_report_health_hint "$stream" "Install curl (see README Requirements)."
    end
end

function __tide_report_health_check_weather_location --description "H-2: invalid Open-Meteo location" --argument-names stream quiet
    set -q tide_report_weather_provider; or set -l tide_report_weather_provider openmeteo
    test "$tide_report_weather_provider" = openmeteo; or return 0

    set -q tide_report_weather_location; or set -l tide_report_weather_location ""
    set -l loc (string trim -- "$tide_report_weather_location")
    test -n "$loc"; or return 0

    if set -q TIDE_REPORT_TEST_VALIDATE_WEATHER_FAIL
        __tide_report_health_warn "$stream" "tide_report_weather_location could not be validated (test fixture)."
        __tide_report_health_hint "$stream" "Run tide-report configure or: set -U tide_report_weather_location 'City'"
        return 0
    end

    if not functions -q _tide_report_validate_weather_location
        source (status filename | path dirname)/_tide_report_validate_weather_location.fish
    end
    set -l err (_tide_report_validate_weather_location "$loc" 2>&1 | string collect)
    if test $status -ne 0
        __tide_report_health_warn "$stream" "tide_report_weather_location is invalid for Open-Meteo."
        test -n "$err"; and __tide_report_health_hint "$stream" "$err"
        __tide_report_health_hint "$stream" "Run tide-report configure or fix the universal."
    end
end

function __tide_report_health_check_moon_wttr --description "H-3: moon wttr dependencies and location coupling" --argument-names stream
    set -q tide_report_moon_provider; or return 0
    test "$tide_report_moon_provider" = wttr; or return 0

    if not __tide_report_health_cmd curl; or not __tide_report_health_cmd jq
        __tide_report_health_warn "$stream" "moon provider wttr requires curl and jq (see dependency warnings above)."
    end

    set -q tide_report_weather_provider; or set -l tide_report_weather_provider openmeteo
    set -q tide_report_weather_location; or set -l tide_report_weather_location ""
    set -l loc (string trim -- "$tide_report_weather_location")

    if test "$tide_report_weather_provider" != wttr; and test -z "$loc"
        __tide_report_health_warn "$stream" "moon wttr uses tide_report_weather_location in the URL; location is empty while weather provider is not wttr."
        __tide_report_health_hint "$stream" "Set a fixed location, use tide_report_moon_provider local, or set weather provider to wttr to share one fetch."
    else if test "$tide_report_weather_provider" = wttr; and test -z "$loc"
        __tide_report_health_info "$stream" "wttr uses IP-based location for weather and moon."
    end
end

function __tide_report_health_check_tide_station --description "H-4 and H-5: tide station ID and US-only info" --argument-names stream quiet
    set -q tide_report_tide_station_id; or set -l tide_report_tide_station_id ""
    set -l station (string trim -- "$tide_report_tide_station_id")

    __tide_report_health_info "$stream" "Tide data is US-only (NOAA). Pick a station: https://tidesandcurrents.noaa.gov/"

    if test -z "$station"
        __tide_report_health_warn "$stream" "tide_report_tide_station_id is not set."
        __tide_report_health_hint "$stream" "Set your station: set -U tide_report_tide_station_id '<id>' (see README)."
        return 0
    end

    if not string match -qr '^[0-9]+$' -- "$station"
        __tide_report_health_warn "$stream" "tide_report_tide_station_id must be numeric (got \"$station\")."
        return 0
    end

    if test "$station" = 8443970
        __tide_report_health_warn "$stream" "Still using the default Boston station (8443970). If you are not near Boston, set your local NOAA station ID."
        __tide_report_health_hint "$stream" "Run tide-report configure or: set -U tide_report_tide_station_id '<id>'"
    end

    if set -q TIDE_REPORT_DOCTOR_SKIP_NETWORK; or set -q TIDE_REPORT_TEST_SKIP_DOCTOR_NETWORK
        return 0
    end
    if not __tide_report_health_cmd curl; or not __tide_report_health_cmd jq
        return 0
    end

    set -q tide_report_service_timeout_millis; or set -l tide_report_service_timeout_millis 6000
    set -q tide_report_user_agent; or set -l tide_report_user_agent "tide-report/unknown"
    set -l timeout_sec (math --scale=0 "$tide_report_service_timeout_millis / 1000")
    set -l current_date (command date +%Y%m%d)
    set -l url "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?product=predictions&interval=hilo&datum=MLLW&time_zone=gmt&units=metric&format=json"
    set url "$url&station=$station&begin_date=$current_date&range=48"
    set -l tide_data (curl -s -A "$tide_report_user_agent" --max-time $timeout_sec "$url")
    if test $status -ne 0; or test -z "$tide_data"
        __tide_report_health_warn "$stream" "Could not reach NOAA for station $station (network or timeout)."
        return 0
    end
    if not printf "%s" "$tide_data" | jq -e '.predictions | length > 0' 2>/dev/null >/dev/null
        __tide_report_health_warn "$stream" "Station ID $station may be invalid or NOAA returned no predictions."
    end
end

function __tide_report_health_check_weather_provider --description "H-6: unknown weather provider" --argument-names stream
    set -q tide_report_weather_provider; or set -l tide_report_weather_provider openmeteo
    if contains -- "$tide_report_weather_provider" openmeteo wttr
        return 0
    end
    __tide_report_health_warn "$stream" "Unknown tide_report_weather_provider \"$tide_report_weather_provider\"; fetches use wttr today."
    __tide_report_health_hint "$stream" "Set: set -U tide_report_weather_provider openmeteo or wttr"
end

function __tide_report_health_check_moon_provider --description "H-7: unknown moon provider" --argument-names stream
    set -q tide_report_moon_provider; or set -l tide_report_moon_provider local
    if contains -- "$tide_report_moon_provider" local wttr
        return 0
    end
    __tide_report_health_warn "$stream" "Unknown tide_report_moon_provider \"$tide_report_moon_provider\"; using local offline model."
    __tide_report_health_hint "$stream" "Set: set -U tide_report_moon_provider local or wttr"
end

function __tide_report_health_check_github --description "H-8: gh auth and repo context" --argument-names stream
    set -q tide_report_github_show_ci; or set -l tide_report_github_show_ci true

    if not __tide_report_health_cmd gh
        __tide_report_health_warn "$stream" "GitHub CLI (gh) is not installed."
        __tide_report_health_hint "$stream" "Install from https://cli.github.com/"
        if test "$tide_report_github_show_ci" = true
            __tide_report_health_hint "$stream" "CI status will not appear until gh is installed and authenticated."
        end
    else if not __tide_report_github_auth_ok_doctor
        __tide_report_health_warn "$stream" "gh is not authenticated for github.com."
        __tide_report_health_hint "$stream" "Run: gh auth login (private repos need repo scope; CI may need workflow read)."
        if test "$tide_report_github_show_ci" = true
            __tide_report_health_hint "$stream" "CI status will not appear until gh is authenticated."
        end
    end

    set -l repo_root (command git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$repo_root"
        __tide_report_health_info "$stream" "GitHub segment only appears inside git repositories."
        return 0
    end
    set -l remote_url (command git config --get remote.origin.url 2>/dev/null)
    if test -z "$remote_url"; or not string match -qr 'github\.com[/:]' "$remote_url"
        __tide_report_health_info "$stream" "GitHub segment only appears when origin is a github.com remote."
    end
end

function __tide_report_health_check_openmeteo_ip --description "H-9: Open-Meteo empty location" --argument-names stream quiet
    set -q tide_report_weather_provider; or set -l tide_report_weather_provider openmeteo
    test "$tide_report_weather_provider" = openmeteo; or return 0
    set -q tide_report_weather_location; or set -l tide_report_weather_location ""
    test -z (string trim -- "$tide_report_weather_location"); or return 0

    __tide_report_health_info "$stream" "Weather uses IP-based location with Open-Meteo. Pin a place with 'set -U tide_report_weather_location City' or tide-report configure if you need a fixed location."

    if set -q TIDE_REPORT_DOCTOR_SKIP_NETWORK; or set -q TIDE_REPORT_TEST_SKIP_DOCTOR_NETWORK
        return 0
    end
    if set -q TIDE_REPORT_TEST_IP_GEO_FAIL
        __tide_report_health_warn "$stream" "IP-based weather location auto-detect failed (test fixture)."
        __tide_report_health_hint "$stream" "Set an explicit tide_report_weather_location."
        return 0
    end

    if not __tide_report_health_cmd curl; or not __tide_report_health_cmd jq
        return 0
    end

    if not functions -q __tide_report_read_ip_location_cache
        source (status filename | path dirname)/_tide_report_weather_helpers.fish
    end
    set -l now (command date +%s)
    set -l cached (__tide_report_read_ip_location_cache "$now" 86400 2>/dev/null)
    if test -n "$cached"
        return 0
    end

    set -q tide_report_service_timeout_millis; or set -l tide_report_service_timeout_millis 6000
    set -l timeout_sec (math --scale=0 "$tide_report_service_timeout_millis / 1000")
    set -q tide_report_user_agent; or set -l tide_report_user_agent "tide-report/unknown"
    set -l ip_json (curl -s -A "$tide_report_user_agent" --max-time $timeout_sec "https://ipapi.co/json/")
    if test $status -ne 0; or test -z "$ip_json"
        __tide_report_health_warn "$stream" "IP-based weather location auto-detect failed."
        __tide_report_health_hint "$stream" "Set an explicit tide_report_weather_location."
        return 0
    end
    if not printf "%s" "$ip_json" | jq -e '.latitude != null and .longitude != null' 2>/dev/null >/dev/null
        __tide_report_health_warn "$stream" "IP-based weather location auto-detect failed."
        __tide_report_health_hint "$stream" "Set an explicit tide_report_weather_location."
    end
end

function __tide_report_health_check_display --description "H-11: Nerd Font and fish_emoji_width" --argument-names stream quiet
    test "$quiet" = --quiet; and return 0
    __tide_report_health_info "$stream" "Icons and emoji work best with a Nerd Font (see README Troubleshooting)."
    if __tide_report_health_fish_at_least 4 6
        set -l emoji_w 2
        if set -q fish_emoji_width
            set emoji_w "$fish_emoji_width"
        end
        if test "$emoji_w" = 2
            __tide_report_health_hint "$stream" "If symbols look misaligned, try: set -U fish_emoji_width 1"
        end
    end
end

function _tide_report_run_health_checks --description "Run configuration health checks for enabled prompt items" --argument-names quiet for_bug_report
    set -l stream stderr
    test "$for_bug_report" = for_bug_report; and set stream stdout

    set -l enabled (_tide_report_enabled_items)
    if test (count $enabled) -eq 0
        if test "$quiet" != --quiet
            __tide_report_health_info "$stream" "No TideReport prompt items are enabled in tide_left_prompt_items / tide_right_prompt_items."
        end
        return 0
    end

    __tide_report_health_check_dependencies $enabled $stream $quiet

    if contains -- weather $enabled
        __tide_report_health_check_weather_provider $stream
        __tide_report_health_check_weather_location $stream $quiet
        __tide_report_health_check_openmeteo_ip $stream $quiet
    end

    if contains -- moon $enabled
        __tide_report_health_check_moon_provider $stream
        __tide_report_health_check_moon_wttr $stream
    end

    if contains -- tide $enabled
        __tide_report_health_check_tide_station $stream $quiet
    end

    if contains -- github $enabled
        __tide_report_health_check_github $stream
    end

    __tide_report_health_check_display $stream $quiet

    if test "$for_bug_report" != for_bug_report
        _tide_report_health_prompt_list_reminders $stream
    end
end
