source "/home/mrbasa/Dev/TideReport/test/setup.fish"
set -g tide_report_github_icon "$tide_report_github_icon"
set -g tide_report_github_icon_stars "★"
set -g tide_report_github_icon_forks "⑂"
set -g tide_report_github_icon_watchers ""
set -g tide_report_github_icon_issues "!"
set -g tide_report_github_icon_prs "PR"
__tide_report_parse_github "/home/mrbasa/Dev/TideReport/test/cache/github/Owner-Repo.json"
if set -q _tide_print_item_calls; and test (count _tide_print_item_calls) -ge 1
  string replace "github " "" "$_tide_print_item_calls[1]"
end
