# TideReport :: Moon Prompt Item
#
# This function handles all logic for displaying the moon phase module.

function _tide_item_moon --description "Displays moon phase in the Tide prompt"
    set -l cache_file ~/.cache/tide-report/moon.txt
    set -l now (date +%s)
    set -l should_fetch false
    set -l url "$tide_report_wttr_url/Moon?format=$tide_report_moon_format"

    _tide_print_item moon "Moon " $tide_report_moon_expire_seconds
    return

    # 1. Check if cache file exists
    if not test -f $cache_file
        set prompt_text $tide_report_moon_unavailable_text
        _tide_report_fetch $url $cache_file "tide_report_moon_updated"
        return
    end

    # 2. If it exists, calculate its age
    set -l cache_mod_time (date -r $cache_file +%s)
    set -l cache_age (math $now - $cache_mod_time)

    # 3. Check if cache is expired
    if test $cache_age -gt $tide_report_moon_expire_seconds #tide_report_moon_expire_seconds
        echo $tide_report_moon_unavailable_text
        set should_fetch true
    else
        # 4. If not expired, display data and check if it's stale
        cat $cache_file
        if test $cache_age -gt $tide_report_moon_refresh_seconds
            set should_fetch true
        end
    end

    # 5. Trigger fetch if needed
    if $should_fetch
        _tide_report_fetch $url $cache_file "tide_report_moon_updated"
    end
end

