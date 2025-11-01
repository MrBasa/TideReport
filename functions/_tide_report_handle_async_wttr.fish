# TideReport :: Private Helper Functions for WTTR data

function _tide_report_handle_async_wttr --argument-names item_name cache_file url refresh_seconds expire_seconds unavailable_text unavailable_color timeout_sec
    set -l now (date +%s)
    set -l output
    set -l trigger_fetch false

    # Check cache status
    if test -f "$cache_file"
        set -l mod_time (date -r "$cache_file" +%s 2>/dev/null; or echo 0)
        set -l cache_age (math $now - $mod_time)
        if test $cache_age -le $expire_seconds
            set output (cat "$cache_file")
            test $cache_age -gt $refresh_seconds && set trigger_fetch true
        else
            set output (set_color $unavailable_color)$unavailable_text
            set trigger_fetch true
        end
    else
        set output (set_color $unavailable_color)$unavailable_text
        set trigger_fetch true
    end

    # Trigger background fetch if needed
    if $trigger_fetch
        set -l lock_var "_tide_report_$item_name_lock"
        set -l lock_time (set -q $lock_var; and echo $$lock_var; or echo 0)
        test (math $now - $lock_time) -gt 120 && set -U $lock_var $now && __tide_report_fetch_and_cache $item_name $url $cache_file $timeout_sec $lock_var &
    end

    # Clean and output
    set output (string replace -a '\t' ' ' -- $output | string replace -ra ' {2,}' ' ')
    _tide_print_item $item_name $output
end

# --- Fetch, Validate & Cache ---
function __tide_report_fetch_and_cache --argument data_type url cache_file timeout_sec lock_var
    # Auto-cleanup lock on exit
    function _remove_lock --on-process-exit $fish_pid --on-signal INT --on-signal TERM --inherit-variable lock_var
        set -e $lock_var
    end

    # Fetch with timeout
    set -l fetched_data (curl -s -A "tide-report/1.0" --max-time $timeout_sec "$url" | string collect)
    echo $fetched_data > ~/tmp.log
    # Validate and cache
    if test $status -eq 0 && test -n "$fetched_data" && test (string length -- "$fetched_data") -le 200 && test (count (string split \n -- "$fetched_data")) -eq 1 \
        && not string match -q -r "(Unknown|Follow|invalid|Sorry|Error)" -- (string lower -- "$fetched_data")

        mkdir -p (dirname "$cache_file")
        set -l temp_file "$cache_file.$fish_pid.tmp"
        echo "$fetched_data" > "$temp_file" && command mv -f "$temp_file" "$cache_file"
    end
end
