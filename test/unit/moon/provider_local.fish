source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_provider_moon_local.fish"

set -l tmp (mktemp -d)
set -l cache "$tmp/moon.json"

@test "provider_moon_local writes normalized cache" (
    __tide_report_provider_moon_local "$cache" 5 _lock
    test -f "$cache"; and jq -e '.phase != null' "$cache" >/dev/null 2>&1
    echo $status
) -eq 0

@test "moon_phase_from_unix returns known phase" (
    set -l p (__tide_report_moon_phase_from_unix 1704067200)
    string match -q -r '^(New Moon|Waxing Crescent|First Quarter|Waxing Gibbous|Full Moon|Waning Gibbous|Last Quarter|Waning Crescent)$' "$p"
    echo $status
) -eq 0

command rm -rf "$tmp"
