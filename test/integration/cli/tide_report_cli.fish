## Integration: tide-report CLI dispatcher.

source (dirname (dirname (status filename)))/../helpers/setup.fish

set -g _tide_report_version "9.9.9"
set -g fish_function_path "$REPO_ROOT/functions" $fish_function_path

@test "tide-report --version prints plugin version" (
    set -l out (tide-report --version 2>&1 | string collect)
    string match -q '*9.9.9*' "$out"
    echo $status
) -eq 0

@test "tide-report --help lists configure subcommand" (
    set -l out (tide-report --help 2>&1 | string collect)
    string match -q '*configure*' "$out"
    and string match -q '*tide reload*' "$out"
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
