## TideReport :: Diagnostic log for expected issues (missing dep, API failure, etc.)
## Writes to $XDG_STATE_HOME/tide-report/tide-report.log (fallback ~/.local/state).

function __tide_report_log_expected --description "Append one line (timestamp, version, category, message) to the TideReport diagnostic log" --argument-names category message
    set -q tide_report_log_expected || return
    set -l v "$tide_report_log_expected"
    string match -q -r '^(0|false|no|off)$' (string lower -- "$v") && return

    set -l state "$HOME/.local/state"
    if set -q XDG_STATE_HOME; and string length -q "$XDG_STATE_HOME"
        set state "$XDG_STATE_HOME"
    end
    set -l log_dir "$state/tide-report"
    set -l log_file "$log_dir/tide-report.log"

    set -l ts (command date -Iseconds 2>/dev/null; or echo "")
    set -l ver ""
    if set -q _tide_report_version; and string length -q "$_tide_report_version"
        set ver "$_tide_report_version"
    else if set -q tide_report_user_agent; and string length -q "$tide_report_user_agent"
        set ver (string replace -r '^tide-report/' '' -- "$tide_report_user_agent")
    end
    set -q ver[1]; or set ver "?"

    mkdir -p "$log_dir"
    printf "%s\t%s\t%s\t%s\n" "$ts" "$ver" "$category" "$message" >> "$log_file"
end
