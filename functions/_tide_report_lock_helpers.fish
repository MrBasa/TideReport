## TideReport :: Cache lock helpers
##
## Prompt rendering should not write Fish universal variables. These helpers use
## per-item lock directories under the TideReport cache instead.

function __tide_report_lock_root --description "Return the TideReport lock root"
    echo "$HOME/.cache/tide-report/locks"
end

function __tide_report_lock_path --description "Return the lock directory for a lock name" --argument-names lock_name
    echo (__tide_report_lock_root)"/$lock_name.lock"
end

function __tide_report_lock_acquire --description "Acquire a cache lock when absent or stale" --argument-names lock_name now ttl_seconds
    set -l lock_root (__tide_report_lock_root)
    set -l lock_dir (__tide_report_lock_path "$lock_name")
    set -l ts_file "$lock_dir/ts"

    mkdir -p "$lock_root" 2>/dev/null
    if mkdir "$lock_dir" 2>/dev/null
        printf "%s\n" "$now" > "$ts_file"
        return 0
    end

    set -l lock_time 0
    if test -f "$ts_file"
        read -l lock_time < "$ts_file"
    end
    string match -qr '^[0-9]+$' -- "$lock_time"; or set lock_time 0

    if test (math "$now - $lock_time") -gt $ttl_seconds
        command rm -rf "$lock_dir" 2>/dev/null
        if mkdir "$lock_dir" 2>/dev/null
            printf "%s\n" "$now" > "$ts_file"
            return 0
        end
    end

    return 1
end

function __tide_report_lock_release --description "Release a cache lock" --argument-names lock_name
    command rm -rf (__tide_report_lock_path "$lock_name") 2>/dev/null
end
