# TideReport :: GitHub Prompt Item
#
# This is the main function that Tide calls to display GitHub data. 

function _tide_item_github --description "Fetches and displays GitHub information for Tide"

    # --- Check if Git repo ---
    if not git rev-parse --is-inside-work-tree &>/dev/null
        return 0
    end

    # --- Check GH auth ---
    if not gh auth status &>/dev/null
        _tide_print_item github (set_color red)"!auth"
        return 0
    end

    # --- Get repo name & owner ---
    set -l current_repo (gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)
    if test -z "$current_repo"
        return 0
    end

    set -l parts (string split "/" $current_repo)
    set -l owner $parts[1]
    set -l repo $parts[2]

    # --- Fetch GH data ---
    set -l query 'query($owner: String!, $repo: String!) { repository(owner: $owner, name: $repo) { stargazerCount forkCount issues(states: OPEN) { totalCount } pullRequests(states: OPEN) { totalCount } } }'
    set -l variables '{"owner":"'$owner'", "repo":"'$repo'"}'
    set -l cmd_list gh api /graphql -X POST -f "query=$query" -f "variables=$variables"
    set github_data ($cmd_list 2>/dev/null | string collect)

    # Check for empty response or API errors
    if test -z "$github_data"; or string match -q -- '*"errors":*' $github_data
        return 1
    end

    # --- Parsing and Formatting ---
    echo "$github_data" | jq \
        '.data.repository | "\(.stargazerCount)\n\(.forkCount)\n\(.issues.totalCount)\n\(.pullRequests.totalCount)"' -r 2>/dev/null \
        | read -l stars forks issues prs

    # --- Output ---
    _tide_print_item git $tide_report_github_icon' ' (
        set_color $tide_report_github_color_stars; echo -ns ' ★'$stars
        set_color $tide_report_github_color_forks; echo -ns ' ⑂'$forks
        set_color $tide_report_github_color_issues; echo -ns ' !'$issues
        set_color $tide_report_github_color_prs; echo -ns ' PR'$prs)
end
