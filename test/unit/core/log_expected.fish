source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/__tide_report_log_expected.fish"

set -l tmp (mktemp -d)
set -g HOME "$tmp/home"
set -g XDG_STATE_HOME "$tmp/state"
mkdir -p "$HOME" "$XDG_STATE_HOME"
set -g _tide_report_version "1.6.1"

@test "log_expected writes one line when enabled" (
    set -g tide_report_log_expected 1
    __tide_report_log_expected weather "api timeout"
    test -f "$XDG_STATE_HOME/tide-report/tide-report.log"
    echo $status
) -eq 0

@test "log_expected does not write when disabled" (
    set -g tide_report_log_expected no
    __tide_report_log_expected weather "should-not-log"
    string match -q '*should-not-log*' (cat "$XDG_STATE_HOME/tide-report/tide-report.log" 2>/dev/null)
    set -l found $status
    test $found -eq 0; and echo 1; or echo 0
) -eq 0

command rm -rf "$tmp"
