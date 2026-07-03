function _tide_report_sub_configure --description "Run the TideReport configuration wizard"
    if not status is-interactive
        echo "tide-report configure: requires an interactive terminal." >&2
        return 1
    end

    if not functions -q _tide_report_install_show_preview
        source (status dirname)/_tide_report_prompt_helpers.fish
    end

    set -l default_color $tide_time_color
    set -l default_bg_color $tide_time_bg_color
    _tide_report_run_wizard "$default_color" "$default_bg_color"

    if not functions -q _tide_report_run_health_checks
        source (status dirname)/_tide_report_health_checks.fish
    end
    _tide_report_run_health_checks
end
