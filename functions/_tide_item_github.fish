# TideReport :: GitHub Prompt Item
#
# This is the main function that Tide calls to display GitHub data. 

function _tide_item_github
    # --- Quick Checks
    git rev-parse --is-inside-work-tree &>/dev/null || return 0 # Not git dir
    gh auth status &>/dev/null || begin; _tide_print_item github (set_color red)"!auth"; return 0; end

    set -q _tide_report_gh_timestamp || set -U _tide_report_gh_timestamp 0
    set -q _tide_report_gh_dir || set -U _tide_report_gh_dir ""
    set -q _tide_report_gh_cache || set -U _tide_report_gh_cache ""

    set -l now (date +%s)
    set -l time_since_fetch (math $now - $_tide_report_gh_timestamp 2>/dev/null; or echo 999999)

    # --- Check for Refresh ---
    if test "$_tide_report_gh_dir" != "$PWD" -o $time_since_fetch -gt $tide_report_github_refresh_seconds
        set -l repo_data (gh repo view --json nameWithOwner,stargazerCount,forkCount,issues,pullRequests 2>/dev/null)

        if test $status -eq 0 -a -n "$repo_data"
            echo $repo_data | jq -r '[.stargazerCount, .forkCount, .issues.totalCount, .pullRequests.totalCount] | @tsv' 2>/dev/null | read -l stars forks issues prs

            if test $status -eq 0
                set -l output
                test "$stars" != "0" -a -n "$stars" && set output "$output"(set_color $tide_report_github_color_stars)" ★$stars"
                test "$forks" != "0" -a -n "$forks" && set output "$output"(set_color $tide_report_github_color_forks)" ⑂$forks"
                test "$issues" != "0" -a -n "$issues" && set output "$output"(set_color $tide_report_github_color_issues)" !$issues"
                test "$prs" != "0" -a -n "$prs" && set output "$output"(set_color $tide_report_github_color_prs)" PR$prs"

                set -U _tide_report_gh_cache "$output"
                set -U _tide_report_gh_dir "$PWD"
                set -U _tide_report_gh_timestamp $now
            else
                set -U _tide_report_gh_cache ""
            end
        else
            set -U _tide_report_gh_cache ""
            set -U _tide_report_gh_dir "$PWD"
        end
    end

    test -n "$_tide_report_gh_cache" && _tide_print_item github "$tide_report_github_icon$_tide_report_gh_cache"
end
