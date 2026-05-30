function tide-report --description "Manage TideReport configuration"
    argparse --stop-nonopt v/version h/help -- $argv

    if set -q _flag_version
        set -q _tide_report_version; or set -l _tide_report_version "?"
        echo "tide-report, version $_tide_report_version"
    else if set -q _flag_help
        _tide_report_help
    else if functions --query _tide_report_sub_$argv[1]
        _tide_report_sub_$argv[1] $argv[2..]
    else
        _tide_report_help
        return 1
    end
end

function _tide_report_help --description "Print tide-report usage"
    printf %s\n \
        'Usage: tide-report [options] subcommand' \
        '' \
        'Options:' \
        '  -v or --version  print tide-report version number' \
        '  -h or --help     print this help message' \
        '' \
        'Subcommands:' \
        '  configure   run interactive configuration wizard' \
        '' \
        'See also: After manual `set -U` changes, run `tide reload`.'
end
