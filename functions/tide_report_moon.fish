# TideReport :: Moon Prompt Item
#
# This function handles all logic for displaying the moon phase module.

function tide_report_moon --description "Displays moon phase in the Tide prompt"
    set -l cache_file ~/.cache/tide_report/moon.txt
    set -l url "$tide_report_wttr_url/Moon?format=$tide_report_moon_format"

    # 1. Handle case where cache file does not exist
    if not test -f $cache_file
        echo $tide_report_moon_unavailable_text
        _tide_report_fetch $url $cache_file
        return
    end

    # 2. Get the age of the cache file (assumes GNU stat for -c %Y)
    set -l mod_time (stat -c %Y $cache_file 2>/dev/null)
    if test $status -ne 0
        echo $tide_report_moon_unavailable_text
        return
    end

    set -l current_time (date +%s)
    set -l cache_age (math $current_time - $mod_time)

    # 3. Handle case where cache is expired
    if test $cache_age -gt $tide_report_moon_expire_seconds
        echo $tide_report_moon_unavailable_text
        _tide_report_fetch $url $cache_file
        return
    end

    # 4. Handle case where cache is stale (but still valid)
    if test $cache_age -gt $tide_report_moon_refresh_seconds
        cat $cache_file # Display the current (stale) data
        _tide_report_fetch $url $cache_file # Trigger refresh
        return
    end

    # 5. Handle case where cache is fresh
    cat $cache_file
end
