## Integration: prompt item placement and idempotency.

set -l tmp (mktemp -d)
set -g HOME "$tmp/home"
set -g XDG_CONFIG_HOME "$tmp/config"
mkdir -p "$HOME" "$XDG_CONFIG_HOME"
source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_do_install.fish"

set -U tide_left_prompt_items git pwd
set -U tide_right_prompt_items time
_tide_report_apply_prompt_items github "weather moon"
set -l left1 (string join ' ' $tide_left_prompt_items)
set -l right1 (string join ' ' $tide_right_prompt_items)

@test "github is inserted after git on left" (
    string match -q 'git github*' "$left1"
    echo $status
) -eq 0

@test "weather and moon are appended on right" (
    string match -q '*time weather moon*' "$right1"
    echo $status
) -eq 0

@test "apply_prompt_items is idempotent" (
    _tide_report_apply_prompt_items github "weather moon"
    test (count (string match -a github $tide_left_prompt_items)) -eq 1; and test (count (string match -a weather $tide_right_prompt_items)) -eq 1
    echo $status
) -eq 0

command rm -rf "$tmp"
