# TideReport :: NOAA Validation Helper
#
# Checks if fetched NOAA data is valid.
# Usage: _tide_report_validate_noaa $curl_status $data $log_name $url

function _tide_report_validate_noaa --description "Validates fetched NOAA JSON data and logs errors" --argument-names curl_status data log_name url
    set -l log_message
    set -l is_valid false

    if test $curl_status -ne 0
        set log_message "curl error (status: $curl_status)"
    else if test -z "$data"
        set log_message "fetch returned empty data"
    else
        # Try to parse the JSON and check for keys
        set -l error_message (echo $data | jq -r '.error.message' 2>/dev/null)
        set -l has_predictions (echo $data | jq -e '.predictions' 2>/dev/null)
        set -l jq_status $status

        if test "$error_message" != "null"
            # API returned a specific error
            set log_message "API Error: $error_message"
        else if test $jq_status -ne 0
            # Data is not valid JSON
            set log_message "Failed to parse JSON"
        else if test "$has_predictions" != "null"
            # This is valid data
            set is_valid true
        else
            set log_message "JSON is valid but missing '.predictions' key"
        end
    end

    if $is_valid
        return 0
    end

    # --- Validation Failed ---
    # Log the error
    set -l tmp_dir "$XDG_RUNTIME_DIR"
    if not test -d "$tmp_dir"
        set tmp_dir "/tmp"
    end
    set -l log_file "$tmp_dir/tide-report-$log_name.error.log"

    begin
        echo "---" >> $log_file
        date >> $log_file
        echo "Validation Failed: $log_message" >> $log_file
        echo "URL: '$url'" >> $log_file
        echo "Raw Data: '$data'" >> $log_file
    end 2>/dev/null

    return 1
end
