# TideReport :: GitHub Prompt Item
#
# This is the main function that Tide calls to display GitHub data.

function _tide_item_github --description "Fetches and displays GitHub information for Tide"

    # Check Dependencies (git, gh, jq)
    if not command -q gh
        _tide_print_item github set_color(red) "!gh"
        return 1
    end

    if not command -q jq
        _tide_print_item github set_color(red) "!jq"
        return 1
    end

    if not command -q git
        _tide_print_item github set_color(red) "!git"
        return 1
    end

    # GH auth
    if not gh auth status >/dev/null 2>&1
        _tide_print_item github set_color(red) "!auth"
        return 1
    end

    # Check if Git repo
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        return
    end

    # Get repo name
    set -l current_repo (gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)

    if test -z "$current_repo"
        return
    end

    set -l parts (string split "/" $current_repo)
    set -l owner $parts[1]
    set -l repo $parts[2]

    # --- Data Fetching ---
    set -l query '
        query($owner: String!, $repo: String!) {
          repository(owner: $owner, name: $repo) {
            stargazerCount
            forkCount
            issues(states: OPEN) {
              totalCount
            }
            pullRequests(states: OPEN) {
              totalCount
            }
          }
        }'

    set -l variables '{"owner":"'$owner'", "repo":"'$repo'"}'
    set -l cmd_list gh api /graphql -X POST -f "query=$query" -f "variables=$variables"
    set github_data ($cmd_list 2>/dev/null | string collect)

    # Check for empty response or API errors
    if test -z "$github_data"; or string match -q -- '*"errors":*' $github_data
        return 1
    end

    # --- Parsing and Formatting ---
    set stars (echo "$github_data" | jq '.data.repository.stargazerCount')
    set forks (echo "$github_data" | jq '.data.repository.forkCount')
    set issues (echo "$github_data" | jq '.data.repository.issues.totalCount')
    set prs (echo "$github_data" | jq '.data.repository.pullRequests.totalCount')
    echo "Parsed data: S($stars) F($forks) I($issues) PR($prs)" >> $log_file

    # --- Final Output ---
    set -l message "★$stars ⑂$forks !$issues PR$prs"

    _tide_print_item github $message
    return
end
