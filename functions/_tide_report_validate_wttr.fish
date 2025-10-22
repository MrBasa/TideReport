# TideReport :: Validation Helper
#
# Checks if fetched data is valid. If not, it logs the error and returns status 1.
# Usage: _tide_report_validate $curl_status $weather_data $log_name

function _tide_report_validate_wttr --description "Validates fetched data and logs errors" --argument-names curl_status data log_name url
    set -l log_message
    set -l is_valid true

    if test $curl_status -ne 0
        set log_message "curl error (status: $curl_status)"
        set is_valid false
    else if test -z "$data"
        set log_message "fetch returned empty data"
        set is_valid false
    else if test (string length -- $data) -gt 100
        # wttr.in formats are short. 100 chars is very generous.
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
    set -l log_file "$tmp_dir/tide-report-$log_name.error.log"

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
