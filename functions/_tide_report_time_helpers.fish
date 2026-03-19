## TideReport :: Shared time/date helpers
##
## Kept separate from prompt items so modules can depend on them without
## implicitly sourcing unrelated render/parsing code.

function __tide_report_gnu_date_cmd --description "Detect GNU date command name (gdate/date) or echo nothing on BSD"
    if set -q __tide_report_cached_gnu_date_cmd
        echo $__tide_report_cached_gnu_date_cmd
        return
    end

    set -g __tide_report_cached_gnu_date_cmd ""
    if command -q gdate
        set -g __tide_report_cached_gnu_date_cmd gdate
    else if command date --version 2>/dev/null >/dev/null
        set -g __tide_report_cached_gnu_date_cmd date
    end

    echo $__tide_report_cached_gnu_date_cmd
end

function __tide_report_time_string_to_unix --description "Parse a local time string like \"07:30 AM\" to a Unix timestamp" --argument-names time_str
    if test -z "$time_str"
        echo ""
        return
    end

    set -l gnu_date_cmd (__tide_report_gnu_date_cmd)
    set -l clean_time (string trim -- $time_str)
    if test -n "$gnu_date_cmd"
        $gnu_date_cmd -d "today $clean_time" +%s 2>/dev/null
    else
        set -l today (command date +%Y-%m-%d)
        command date -j -f "%Y-%m-%d %I:%M %p" "$today $clean_time" +%s 2>/dev/null
    end
end

function __tide_report_format_unix_time --description "Format a Unix timestamp using the given time format" --argument-names epoch_str time_format
    if test -z "$epoch_str"; or test "$epoch_str" = "null"
        echo ""
        return
    end

    set -l gnu_date_cmd (__tide_report_gnu_date_cmd)
    if test -n "$gnu_date_cmd"
        $gnu_date_cmd -d @$epoch_str +$time_format 2>/dev/null
    else
        command date -r $epoch_str +$time_format 2>/dev/null
    end
end

function __tide_report_format_wttr_time --description "Re-format wttr.in time strings using the given time format" --argument-names time_str time_format
    if test -z "$time_str"
        echo ""
        return
    end

    set -l gnu_date_cmd (__tide_report_gnu_date_cmd)
    set -l clean_time (string trim -- $time_str)
    set -l epoch_time

    if test -n "$gnu_date_cmd"
        set epoch_time ($gnu_date_cmd -d "$clean_time" +%s 2>/dev/null)
    else
        set epoch_time (command date -j -f "%I:%M %p" "$clean_time" +%s 2>/dev/null)
    end

    if test $status -ne 0; or test -z "$epoch_time"
        echo "$clean_time"
        return
    end

    if test -n "$gnu_date_cmd"
        $gnu_date_cmd -d @$epoch_time +$time_format 2>/dev/null
    else
        command date -r $epoch_time +$time_format 2>/dev/null
    end
end

function __tide_report_iso8601_to_unix --description "Convert ISO8601 date-time string to Unix timestamp" --argument-names iso
    if test -z "$iso"
        echo ""
        return
    end

    set -l gnu_date_cmd (__tide_report_gnu_date_cmd)
    if test -n "$gnu_date_cmd"
        $gnu_date_cmd -d "$iso" +%s 2>/dev/null
    else
        set -l parts (string split 'T' -- $iso)
        if test (count $parts) -ge 2
            command date -j -f "%Y-%m-%dT%H:%M" "$parts[1]T$parts[2]" +%s 2>/dev/null
        end
    end
end
