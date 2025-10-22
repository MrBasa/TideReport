# TideReport :: Moon Prompt Item
#
# This function handles all logic for displaying the moon phase module.

function _tide_item_moon --description "Fetches and displays moon phase for Tide"
    # Setup variables
    set -l cache_file ~/.cache/tide-report/moon.txt
    set -l url "$tide_report_wttr_url/?format=$tide_report_moon_format"
    set -l now (date +%s)
    set -l output ""

    # Check cache status
    set -l cache_age -1
    set -l cache_is_expired true
    if test -f $cache_file
        set -l mod_time (date -r $cache_file +%s 2>/dev/null)
        if test $status -eq 0
            set cache_age (math $now - $mod_time)
            if test $cache_age -le $tide_report_moon_expire_seconds
                set cache_is_expired false
            end
        end
    end

    # Check if cache is fresh
    if test $cache_age -ne -1; and test $cache_age -le $tide_report_moon_refresh_seconds
        set output (cat $cache_file)

    # Cache is stale, expired, or missing. We must fetch.
    else
        set -l timeout_sec (math -s3 "$tide_report_service_timeout_millis / 1000")
        set -l moon_data (curl -s --max-time $timeout_sec $url | string collect)
        set -l curl_status $status

        # Validate the new data
        if _tide_report_validate_wttr $curl_status "$moon_data" "moon" "$url"
            # --- Validation PASSED ---
            set output $moon_data
            mkdir -p (dirname $cache_file)
            echo $moon_data > $cache_file
        else
            # --- Validation FAILED ---
            if not $cache_is_expired
                set output (cat $cache_file)
            else
                set output $tide_report_moon_unavailable_color$tide_report_moon_unavailable_text
            end
        end
    end

    # --- Final Output ---
    # Massage the output: replace tabs and multiple spaces with a single space
    set output (string replace --all '\t' ' ' -- $output)
    set output (string replace --all --regex ' {2,}' ' ' -- $output)

    _tide_print_item moon $output
end


