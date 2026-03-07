set -l repo_root (dirname (dirname (dirname (dirname (status filename)))))
set -l tmp (mktemp -d)
set -g HOME "$tmp/home"
set -g XDG_CONFIG_HOME "$tmp/config"
mkdir -p "$HOME" "$XDG_CONFIG_HOME"

source "$repo_root/conf.d/tide_report.fish"

@test "conf init sets plugin user-agent default" -n "$tide_report_user_agent"
@test "conf init sets log_expected default" -n "$tide_report_log_expected"
@test "conf init installs event handlers" (
    functions -q _tide_report_install; and functions -q _tide_report_update; and functions -q _tide_report_uninstall
    echo $status
) -eq 0

command rm -rf "$tmp"
