# TideReport :: Moon Prompt Item
#
# This function handles all logic for displaying the moon phase module.

function _tide_item_moon --description "Fetches and displays moon phase for Tide"
    # Setup variables
    set -l cache_file ~/.cache/tide-report/moon.txt
    set -l url "$tide_report_wttr_url/Moon?format=$tide_report_moon_format"
    set -l now (date +%s)

    # Check cache status
    set -l cache_age -1
    if test -f $cache_file
        set -l mod_time (date -r $cache_file +%s 2>/dev/null)
        if test $status -eq 0
            set cache_age (math $now - $mod_time)
        end
    end

    # Determine final output based on cache status
    if test $cache_age -gt $tide_report_moon_expire_seconds
        # --- Cache is missing or expired ---

        # Immediately print "unavailable" text.
        _tide_print_item moon $tide_report_moon_unavailable_text

        # Now, synchronously fetch new data.
        set -l timeout_sec (math -s3 "$tide_report_service_timeout_millis / 1000")
        set -l moon_data (curl -s --max-time $timeout_sec $url | string collect)

        if test $status -eq 0 -a -n "$moon_data"
            # Fetch succeeded, update cache and print new data.
            mkdir -p (dirname $cache_file)
            echo $moon_data > $cache_file
            _tide_print_item moon $moon_data
        end
        # If fetch fails, we already printed "unavailable", so we just end.

    else if test $cache_age -gt $tide_report_moon_refresh_seconds
        # --- Cache is stale (but not expired) ---

        # Immediately print the stale cache data.
        _tide_print_item moon (cat $cache_file)

        # Now, synchronously fetch new data.
        set -l timeout_sec (math -s3 "$tide_report_service_timeout_millis / 1000")
        set -l moon_data (curl -s --max-time $timeout_sec $url | string collect)

        if test $status -eq 0 -a -n "$moon_data"
            # Fetch succeeded, update cache and print new data.
            mkdir -p (dirname $cache_file)
            echo $moon_data > $cache_file
            _tide_print_item moon $moon_data
        end
    else
        # --- Cache is fresh ---
        # We are good, just print the cache content and finish.
        _tide_print_item moon (cat $cache_file)
    end
end
