source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_log_expected.fish"

set -l tmp (mktemp -d)
set -g HOME "$tmp/home"
set -g XDG_STATE_HOME "$tmp/state"
mkdir -p "$HOME" "$XDG_STATE_HOME"
set -g _tide_report_version "1.7.0"
set -l log_file "$XDG_STATE_HOME/tide-report/tide-report.log"

function __tide_report_test_log_has_message --argument-names needle
    test -f "$log_file"; and string match -q "*$needle*" (command cat "$log_file")
end

@test "log_expected writes one line when enabled" (
    set -g tide_report_log_expected 1
    command rm -f "$log_file"
    _tide_report_log_expected weather "api timeout"
    test -f "$log_file"
    echo $status
) -eq 0

@test "log_expected uses portable UTC timestamp" (
    set -g tide_report_log_expected 1
    command rm -f "$log_file"
    _tide_report_log_expected weather "ts-check"
    string match -q -r '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z' (command head -n 1 "$log_file")
    echo $status
) -eq 0

@test "log_expected does not write when disabled with no" (
    set -g tide_report_log_expected no
    command rm -f "$log_file"
    _tide_report_log_expected weather "should-not-log-no"
    __tide_report_test_log_has_message "should-not-log-no"; and echo 1; or echo 0
) -eq 0

@test "log_expected does not write when disabled with 0" (
    set -g tide_report_log_expected 0
    command rm -f "$log_file"
    _tide_report_log_expected weather "should-not-log-zero"
    __tide_report_test_log_has_message "should-not-log-zero"; and echo 1; or echo 0
) -eq 0

@test "log_expected does not write when disabled with false" (
    set -g tide_report_log_expected false
    command rm -f "$log_file"
    _tide_report_log_expected weather "should-not-log-false"
    __tide_report_test_log_has_message "should-not-log-false"; and echo 1; or echo 0
) -eq 0

command rm -rf "$tmp"
