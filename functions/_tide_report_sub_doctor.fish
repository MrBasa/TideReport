function _tide_report_sub_doctor --description "Run TideReport configuration health checks"
    if not functions -q _tide_report_run_health_checks
        source (status dirname)/_tide_report_health_checks.fish
    end

    set -l quiet false
    if contains -- --quiet $argv
        set quiet true
    end

    if $quiet
        _tide_report_run_health_checks --quiet
    else
        _tide_report_run_health_checks
    end
    return 0
end
