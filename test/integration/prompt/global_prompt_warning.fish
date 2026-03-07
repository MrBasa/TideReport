## Integration: warning for global prompt variable shadowing.

set -l tmp (mktemp -d)
set -g HOME "$tmp/home"
set -g XDG_CONFIG_HOME "$tmp/config"
mkdir -p "$HOME" "$XDG_CONFIG_HOME"
source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/conf.d/tide_report.fish"

@test "warn_global_prompt_items emits guidance when globals are set" (
    functions -q _tide_report_warn_global_prompt_items
    echo $status
) -eq 0

@test "warn_global_prompt_items is quiet without globals" (
    set -e tide_left_prompt_items
    set -e tide_right_prompt_items
    set -l out (_tide_report_warn_global_prompt_items "git" "time" | string collect)
    test -z "$out"
    echo $status
) -eq 0

command rm -rf "$tmp"
