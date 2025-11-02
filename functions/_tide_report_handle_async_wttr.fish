# TideReport :: Private Helper Functions for WTTR JSON data

# This is the main async handler. It checks the cache and triggers a fetch if needed.
function _tide_report_handle_async_wttr --argument-names item_name cache_file refresh_seconds expire_seconds unavailable_text unavailable_color timeout_sec
    set -l now (command date +%s)
    set -l trigger_fetch false
    set -l cache_valid false

    # Check cache status
    if test -f "$cache_file"
        set -l mod_time (command date -r "$cache_file" +%s 2>/dev/null; or echo 0)
        set -l cache_age (math $now - $mod_time)
        if test $cache_age -le $expire_seconds
            # Cache is valid and not expired.
            set cache_valid true
            # Check if it's stale and needs a refresh.
            test $cache_age -gt $refresh_seconds && set trigger_fetch true
        else
            # Cache is expired.
            set trigger_fetch true
        end
    else
        # No cache file.
        set trigger_fetch true
    end

    # Trigger background fetch if needed
    if $trigger_fetch
        set -l lock_var "_tide_report_wttr_lock"
        set -l lock_time (set -q $lock_var; and echo $$lock_var; or echo 0)

        # Check 120s cooldown (lock fail-safe)
        if test (math $now - $lock_time) -gt 120
            set -U $lock_var $now
            # Construct the JSON URL
            set -l url "$tide_report_wttr_url/$tide_report_weather_location?format=j1&lang=$tide_report_weather_language"
            # Fetch in background
            __tide_report_fetch_wttr_json "$url" "$cache_file" "$timeout_sec" "$lock_var" &
        end
    end

    # Return status: 0 if cache is valid, 1 if not.
    if $cache_valid
        return 0
    else
        # If cache is not valid, print unavailable text and return failure.
        _tide_print_item $item_name (set_color $unavailable_color)$unavailable_text
        return 1
    end
end

# --- Fetch, Validate & Cache ---
function __tide_report_fetch_wttr_json --argument-names url cache_file timeout_sec lock_var
    # Auto-cleanup lock on exit
    function _remove_lock --on-process-exit $fish_pid --on-signal INT --on-signal TERM --inherit-variable lock_var
        set -e $lock_var
    end

    # Fetch with timeout, requesting JSON
    set -l fetched_data (curl -s -A "tide-report/1.1" --max-time $timeout_sec "$url")
    set -l curl_status $status

    if test $curl_status -ne 0; or test -z "$fetched_data"
        return # Curl failed
    end

    # Validate JSON with jq
    if printf "%s" "$fetched_data" | jq -e '.current_condition | length > 0' >/dev/null 2>&1
        # Cache is valid, write it
        mkdir -p (dirname "$cache_file")
        set -l temp_file "$cache_file.$fish_pid.tmp"
        printf "%s" "$fetched_data" > "$temp_file" && command mv -f "$temp_file" "$cache_file"
    end
end
