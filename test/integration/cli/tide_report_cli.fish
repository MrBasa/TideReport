## Integration: tide-report CLI dispatcher.

source (dirname (dirname (status filename)))/../helpers/setup.fish

set -g _tide_report_version "9.9.9"
set -g fish_function_path "$REPO_ROOT/functions" $fish_function_path

@test "tide-report --version prints plugin version" (
    set -l out (tide-report --version 2>&1 | string collect)
    string match -q '*9.9.9*' "$out"
    echo $status
) -eq 0

@test "tide-report --help lists configure doctor and bug-report" (
    set -l out (tide-report --help 2>&1 | string collect)
    string match -q '*configure*' "$out"
    and string match -q '*doctor*' "$out"
    and string match -q '*bug-report*' "$out"
    and string match -q '*tide reload*' "$out"
    echo $status
) -eq 0

@test "tide-report doctor subcommand is registered" (
    functions -q _tide_report_sub_doctor
    echo $status
) -eq 0

@test "tide-report bug-report prints issue URL and version" (
    set -l out (tide-report bug-report 2>/dev/null | string collect)
    string match -q '*github.com/MrBasa/TideReport/issues/new*' "$out"
    and string match -q '*9.9.9*' "$out"
    and string match -q '*configuration health*' "$out"
    echo $status
) -eq 0

@test "tide-report configure requires interactive terminal" (
    tide-report configure 2>/dev/null
    echo $status
) -eq 1

@test "tide-report unknown subcommand exits non-zero" (
    tide-report nosuch >/dev/null 2>/dev/null
    echo $status
) -eq 1
