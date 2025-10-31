# TideReport :: GitHub Prompt Item
#
# This is the main function that Tide calls to display GitHub data. 

function _tide_item_github --description "Displays GitHub info from a global cache"

    # --- Quick Checks ---
    if not git rev-parse --is-inside-work-tree &>/dev/null
        return 0 # Not a git repo
    end
    if not gh auth status &>/dev/null
        _tide_print_item github (set_color red)"!auth"
        return 0 # No GitHub auth
    end

    # --- Get Current Repo State ---
    set -l current_repo (gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)
    if test -z "$current_repo"
        return 0 # Not a GitHub repo
    end

    set -l now (date +%s)
    set -l output
    set -l do_fetch false

    # --- Fetch Needed? ---
    set -l last_fetch_time $_tide_report_gh_last_fetch_time
    if test -z "$last_fetch_time"
        set last_fetch_time 0 # Default to 0 if unset
    end

    if test "$_tide_report_gh_last_repo" != "$current_repo"
        set do_fetch true # Repo has changed, we must fetch
    else if test (math $now - $last_fetch_time 2>/dev/null) -gt $tide_report_github_refresh_seconds
        set do_fetch true # Repo is the same, but cache is stale
    end

    # --- Fetch or Use Cache ---
    if $do_fetch
        # 1. Fetch data synchronously
        set -l parts (string split "/" $current_repo)
        set -l owner $parts[1]
        set -l repo $parts[2]
        set -l timeout_sec (math --scale=0 "$tide_report_service_timeout_millis / 1000" 2>/dev/null)
        set -l query 'query($owner: String!, $repo: String!) { repository(owner: $owner, name: $repo) { stargazerCount forkCount issues(states: OPEN) { totalCount } pullRequests(states: OPEN) { totalCount } } }'
        set -l variables '{"owner":"'$owner'", "repo":"'$repo'"}'
        set -l fetched_data (gh api /graphql -X POST -f "query=$query" -f "variables=$variables" 2>/dev/null | string collect)
        set -l gh_status $status

        # 2. Validate and Parse
        if test $gh_status -eq 0; and not test -z "$fetched_data"; and not string match -q -- '*"errors":*' "$fetched_data"
            echo "$fetched_data" | jq \
                '.data.repository | "\(.stargazerCount) \(.forkCount) \(.issues.totalCount) \(.pullRequests.totalCount)"' -r 2>/dev/null \
                | read -l stars forks issues prs

            # 3. Format output string if parsing succeeded
            if test $status -eq 0
                set output (
                    test -n "$stars" -a "$stars" != "0"; and set_color $tide_report_github_color_stars; and echo -ns ' ★'$stars
                    test -n "$forks" -a "$forks" != "0"; and set_color $tide_report_github_color_forks; and echo -ns ' ⑂'$forks
                    test -n "$issues" -a "$issues" != "0"; and set_color $tide_report_github_color_issues; and echo -ns ' !'$issues
                    test -n "$prs" -a "$prs" != "0"; and set_color $tide_report_github_color_prs; and echo -ns ' PR'$prs
                )

                # 4. Set global cache variables
                set -gx _tide_report_gh_cached_output $output
                set -gx _tide_report_gh_last_repo "$current_repo"
                set -gx _tide_report_gh_last_fetch_time $now
            else
                # Parse failed
                set output (set_color $tide_report_github_color_issues)"!parse"
            end
        else
            # Fetch failed
            echo $fetched_data >> ~/temp.log
            set output (set_color $tide_report_github_color_issues)"!fetch"
        end
    else
        # Use cached data
        set output $_tide_report_gh_cached_output
    end

    _tide_print_item github $tide_report_github_icon $output
end
