# TideReport :: Private Helper Functions for WTTR data

function _tide_report_handle_async_wttr --description "Handles display and async fetching for cached items" \
    --argument-names item_name cache_file url refresh_seconds expire_seconds unavailable_text unavailable_color timeout_sec

    set -l now (date +%s)
    set -l output ""
    set -l trigger_fetch false

    # Check cache status
    set -l cache_age -1
    set -l cache_exists false
    set -l cache_is_expired true
    if test -f "$cache_file"
        set cache_exists true
        # Suppress errors from stat/date if file disappears between checks
        set -l mod_time (date -r "$cache_file" +%s 2>/dev/null)
        if test $status -eq 0
            set cache_age (math $now - $mod_time)
            if test $cache_age -le $expire_seconds
                set cache_is_expired false
            end
        end
    end

    # --- Check Cache ---
    if $cache_exists; and not $cache_is_expired
        # Cache exists and is NOT expired
        set output (cat "$cache_file")
        # Trigger fetch only if cache is stale (older than refresh_seconds)
        if test $cache_age -gt $refresh_seconds
            set trigger_fetch true
        end
    else
        # Cache doesn't exist or it's expired
        set output (set_color $unavailable_color)$unavailable_text
        set trigger_fetch true
    end

    # --- Trigger Background Fetch ---
    if $trigger_fetch
        # Use an item-specific universal variable for the lock
        set -l lock_var_name "_tide_report_$item_name_timestamp"
        set -l lock_time (set $lock_var_name)
        if test -z "$lock_time"; set lock_time 0; end # Default to 0 if unset

        set -l is_locked false
        if test $lock_time -gt 0
            # Lock is set, check if it's stale
            set -l lock_age (math $now - $lock_time)
            if test $lock_age -le $tide_report_lock_timeout_seconds
                set is_locked true # Lock is active and not stale
            end
            # If lock is stale, we'll ignore it and proceed
        end

        if not $is_locked
            # Set the lock with the current time
            set -U $lock_var_name $now

            # 2. Start the background fetch
            _tide_report_fetch_and_cache \
                $item_name \
                $url \
                $cache_file \
                $timeout_sec \
                $_tide_report_tmp_dir \
                $lock_var_name &>/dev/null &
        end
    end

    # --- Output ---
    # Massage the output: replace tabs and multiple spaces with a single space
    set output (string replace --all '\t' ' ' -- $output)
    set output (string replace --all --regex ' {2,}' ' ' -- $output)

    _tide_print_item $item_name $output
    return 0
end

function _tide_report_fetch_and_cache --description "Fetches, validates, and caches data in the background" \
    --argument data_type url cache_file timeout_sec tmp_dir lock_var_name

    # Ensure lock variable is cleared on exit, error, or interrupt
    function _remove_lock --on-process-exit $fish_pid --on-signal INT --on-signal TERM --inherit-variable lock_var_name
        set -U $lock_var_name 0
    end

    # Perform the fetch
    set -l fetched_data (curl -s -A "tide-report-script" --max-time $timeout_sec "$url" | string collect)
    set -l curl_status $status

    # Validate and cache if successful
    if _tide_report_validate_wttr $curl_status "$fetched_data" "$data_type" "$url" "$tmp_dir"
        # Validation passed, update cache
        mkdir -p (dirname "$cache_file") &>/dev/null
        # Use a temporary file and atomic move to prevent partial reads
        set -l temp_file "$cache_file.(random).tmp"
        if echo "$fetched_data" > "$temp_file"
            # Ensure the move overwrites the target atomically
            if not command mv -f "$temp_file" "$cache_file"
                rm -f "$temp_file" &>/dev/null
            end
        else
           rm -f "$temp_file" &>/dev/null
        end
    end
    # else: Validation failed, do nothing
end

function _tide_report_validate_wttr --description "Validates fetched data and logs errors" --argument-names curl_status data data_type url tmp_dir
    set -l log_file "$tmp_dir/tide_report_$data_type.error.log"
    set -l log_message
    set -l is_valid true

    if test $curl_status -ne 0
        set log_message "curl error (status: $curl_status)"
        set is_valid false
    else if test -z "$data"
        set log_message "fetch returned empty data"
        set is_valid false
    else if test (string length -- $data) -gt 50
        set log_message "data is unexpectedly long (>$data)"
        set is_valid false
    else if test (string split --max 1 \n -- $data | count) -gt 1
        set log_message "data is multi-line (>$data)"
        set is_valid false
    else if string match -q -r "(Unknown|Follow|invalid)" -- (string lower -- $data)
        # Check for common wttr.in error messages
        set log_message "data contains a known error string (>$data)"
        set is_valid false
    end

    if $is_valid
        return 0
    end

    # Try to create/append to the log
    begin
        echo "---" >> $log_file
        date >> $log_file
        echo "Validation Failed: $log_message" >> $log_file
        echo "URL: '$url'" >> $log_file
        echo "Raw Data: '$data'" >> $log_file
    end 2>/dev/null

    return 1
end
