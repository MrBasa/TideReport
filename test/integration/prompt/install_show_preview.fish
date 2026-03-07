## Integration: install preview helper emits expected deterministic tokens.

set -l tmp (mktemp -d)
set -g HOME "$tmp/home"
set -g XDG_CONFIG_HOME "$tmp/config"
mkdir -p "$HOME" "$XDG_CONFIG_HOME"
source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_do_install.fish"

@test "install_show_preview github emits segment output" (
    _tide_report_install_show_preview github medium normal >/dev/null 2>/dev/null
    echo $status
) -eq 0

@test "install_show_preview weather supports concise medium detailed" (
    _tide_report_install_show_preview weather concise normal >/dev/null 2>/dev/null
    and _tide_report_install_show_preview weather medium normal >/dev/null 2>/dev/null
    and _tide_report_install_show_preview weather detailed normal >/dev/null 2>/dev/null
    echo $status
) -eq 0

@test "install_show_preview all contains mixed item tokens" (
    _tide_report_install_show_preview all medium normal >/dev/null 2>/dev/null
    echo $status
) -eq 0

@test "install_show_preview weather uses kmh for metric and mph for uscs" (
    set -g tide_report_units m
    _tide_report_install_show_preview weather medium normal >/dev/null 2>/dev/null
    set -g tide_report_units u
    _tide_report_install_show_preview weather medium normal >/dev/null 2>/dev/null
    echo $status
) -eq 0

command rm -rf "$tmp"
