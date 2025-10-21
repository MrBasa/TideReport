# TideReport :: Tide Prompt Item
# Displays the next high or low tide from NOAA.

function _tide_item_tide --description "Displays US-based tide information in the Tide prompt"
    # This module requires jq for JSON parsing
    if not command -q jq
        echo "jq required"
        return
    end

    # This module requires a station ID to be set by the user
    if test -z "$tide_report_tide_station_id"
        echo "no station"
        return
    end

    set -l cache_file ~/.cache/tide_report/tide.json
    set -l url "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?product=predictions&application=tide_report_fish&begin_date=(date -u +%Y%m%d)&range=24&datum=MLLW&station=$tide_report_tide_station_id&time_zone=lst_ldt&units=$tide_report_tide_units&format=json"

    # 1. Handle cache non-existence
    if not test -f $cache_file
        echo $tide_report_tide_unavailable_text
        _tide_report_fetch $url $cache_file "tide_report_tide_updated"
        return
    end

    # 2. Check cache age
    set -l mod_time (stat -c %Y $cache_file 2>/dev/null)
    if test $status -ne 0
        echo $tide_report_tide_unavailable_text
        return
    end
    set -l cache_age (math (date +%s) - $mod_time)

    # 3. Handle expired cache
    if test $cache_age -gt $tide_report_tide_expire_seconds
        echo $tide_report_tide_unavailable_text
        _tide_report_fetch $url $cache_file "tide_report_tide_updated"
        return
    end

    # 4. Parse and display data from cache
    set -l next_tide (cat $cache_file | jq -r '.predictions[0] | "\(.type),\(.v),\(.t)"')

    # If parsing fails, show unavailable text
    if test -z "$next_tide"
        echo $tide_report_tide_unavailable_text
    else
        set -l parts (string split ',' $next_tide)
        set -l type $parts[1]
        set -l height $parts[2]
        set -l time (string split ' ' $parts[3])[2] # Get HH:MM part

        set -l arrow
        if test "$type" = "H"
            set arrow $tide_report_tide_arrow_rising
        else
            set arrow $tide_report_tide_arrow_falling
        end

        set -l unit_suffix "ft"
        if test "$tide_report_tide_units" = "metric"
            set unit_suffix "m"
        end

        echo "$arrow $height$unit_suffix @ $time"
    end

    # 5. Handle stale cache (trigger background refresh)
    if test $cache_age -gt $tide_report_tide_refresh_seconds
        _tide_report_fetch $url $cache_file "tide_report_tide_updated"
    end
end
