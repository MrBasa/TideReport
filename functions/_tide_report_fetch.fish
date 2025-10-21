# TideReport :: Generic Async Fetcher
# Fetches a URL, saves it to a cache file, and emits an event upon completion.

function _tide_report_fetch --description "Fetches data and emits an event" --argument-names url cache_file event_name
    # Ensure the cache directory exists
    mkdir -p (dirname $cache_file)

    # Convert the timeout from milliseconds to seconds for curl
    set -l timeout_sec (math -s3 "$tide_report_service_timeout_millis / 1000")

    # Fetch data. Upon completion, emit the specified event.
    begin
        curl -s --max-time $timeout_sec $url > $cache_file
        if test -n "$event_name"
            emit $event_name
        end
    end &; and disown
end
