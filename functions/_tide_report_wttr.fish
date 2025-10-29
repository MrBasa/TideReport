# TideReport :: Private Helper Functions for WTTR data

function _tide_report_is_fetching --description "Checks if a background fetch is running for a data type" --argument data_type
    set -l lock_file "/tmp/tide_report_fetching_$data_type.lock"

    # Check if the lock file exists
    if test -f "$lock_file"
        # Check if the process holding the lock is still running
        # set -l pid (cat "$lock_file" 2>/dev/null)
        # if test -n "$pid"; and ps -p "$pid" >/dev/null
        #     return 0 # Still running
        # else
        #     # Stale lock file, remove it
        #     rm -f "$lock_file" &>/dev/null
        #     return 1
        # end
        return 0 # Assume lock file means it's running or recently finished
    end
    return 1 # Not fetching
end

function _tide_report_fetch_and_cache --description "Fetches, validates, and caches data in the background" --argument data_type url cache_file timeout_sec
    set -l lock_file "/tmp/tide_report_fetching_$data_type.lock"

    # Create lock file with PID
    # Using 'echo %self > "$lock_file"' ensures atomicity better than separate commands
    if not echo %self > "$lock_file"
      # Failed to create lock, maybe concurrent write? Exit silently.
      return 1
    end

    # Ensure lock file is removed on exit, error, or interrupt
    function _remove_lock --on-process-exit %self
        rm -f "$lock_file" &>/dev/null
    end
    # Alternative using trap (might be needed for older fish versions?)
    # trap 'rm -f "$lock_file" &>/dev/null' EXIT INT TERM

    # Perform the fetch
    set -l fetched_data (curl -s --max-time $timeout_sec "$url" | string collect)
    set -l curl_status $status

    # Validate and cache if successful
    if _tide_report_validate_wttr $curl_status "$fetched_data" "$data_type" "$url"
        # Validation passed, update cache
        mkdir -p (dirname "$cache_file") &>/dev/null
        # Use a temporary file and atomic move to prevent partial reads
        set -l temp_file "$cache_file.(random).tmp"
        if echo "$fetched_data" > "$temp_file"
            # Ensure the move overwrites the target atomically
            if not command mv -f "$temp_file" "$cache_file"
                # Handle potential mv error if needed, e.g., permissions
                rm -f "$temp_file" &>/dev/null
            end
        else
           # Handle temp file write error if needed
           rm -f "$temp_file" &>/dev/null
        end
    end
    # else: Validation failed, do nothing, error is logged by _tide_report_validate_wttr

    # Lock file is removed automatically by the --on-process-exit handler
    # or trap. No explicit rm needed here unless using older fish without function events.
end

function _tide_report_handle_async_item --description "Handles display and async fetching for cached items" \
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

    # --- Determine what to display and if fetch is needed ---
    if $cache_exists; and not $cache_is_expired
        # Cache exists and is NOT expired
        set output (cat "$cache_file")
        # Trigger fetch only if cache is STALE (older than refresh_seconds)
        if test $cache_age -gt $refresh_seconds
            set trigger_fetch true
        end
    else
        # Cache doesn't exist OR it's expired
        set output (set_color "$unavailable_color")$unavailable_text(set_color normal)
        set trigger_fetch true
    end

    # --- Trigger background fetch if needed and not already running ---
    if $trigger_fetch; and not _tide_report_is_fetching $item_name
        # Launch the fetch function in the background.
        fish -c "_tide_report_fetch_and_cache '$item_name' '$url' '$cache_file' '$timeout_sec'" &>/dev/null &
    end

    # --- Output ---
    # Massage the output: replace tabs and multiple spaces with a single space
    set output_massaged (string replace --all '\t' ' ' -- $output)
    set output_massaged (string replace --all --regex ' {2,}' ' ' -- $output_massaged)

    _tide_print_item $item_name $output_massaged
    return 0
end

function _tide_report_validate_wttr --description "Validates fetched data and logs errors" --argument-names curl_status data log_name url
    set -l log_file "/tmp/tide-report-$log_name.error.log"
    set -l log_message
    set -l is_valid true

    if test $curl_status -ne 0
        set log_message "curl error (status: $curl_status)"
        set is_valid false
    else if test -z "$data"
        set log_message "fetch returned empty data"
        set is_valid false
    else if test (string length -- $data) -gt 15
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

    # --- Validation Failed ---
    # Log the error to a proper temp file
    set -l tmp_dir "$XDG_RUNTIME_DIR"
    if not test -d "$tmp_dir"
        set tmp_dir "/tmp"
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
