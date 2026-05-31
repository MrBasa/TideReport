## TideReport :: Shared cache helpers
##
## Cache age logic, atomic JSON writes, and file mtime for weather/moon/tide/GitHub paths.

function __tide_report_file_mtime --description "Return file mtime as Unix seconds, or empty on failure" --argument-names file_path
    set -l stamp (path mtime -- "$file_path" 2>/dev/null | string collect | string trim)
    string match -qr '^[0-9]+$' -- "$stamp"; and echo "$stamp"
end

function __tide_report_cache_state --description "Compute cache validity and background-fetch trigger from age thresholds" --argument-names cache_file now refresh_seconds expire_seconds
    set -l trigger_fetch false
    set -l cache_valid false
    set -l stale false

    if test -f "$cache_file"
        set -l mod_time (__tide_report_file_mtime "$cache_file")
        test -n "$mod_time"; or set mod_time 0
        set -l cache_age (math $now - $mod_time)
        if test $cache_age -le $expire_seconds
            set cache_valid true
            if test $cache_age -gt $refresh_seconds
                set trigger_fetch true
                set stale true
            end
        else
            set trigger_fetch true
        end
    else
        set trigger_fetch true
    end

    echo $trigger_fetch
    echo $cache_valid
    echo $stale
end

function __tide_report_write_json_cache --description "Atomically write JSON to a cache file (mkdir parent, pid temp, mv)" --argument-names path json_content
    mkdir -p (dirname "$path")
    set -l temp_file "$path.$fish_pid.tmp"
    printf "%s" "$json_content" > "$temp_file" && command mv -f "$temp_file" "$path"
end
