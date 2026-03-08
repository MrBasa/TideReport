#!/usr/bin/env fish
## Compare local moon phase/illumination to canonical SunCalc fixture.
## Run from repo root. Reads test/fixtures/moon/suncalc_reference.json,
## computes local values at exact fixture timestamps, reports summary and worst diffs.
## Requires: jq, and moon math (sourced below).

set -l script_dir (path dirname (status filename))
set -l repo_root (path dirname $script_dir)
set -l fixture_file "$repo_root/test/fixtures/moon/suncalc_reference.json"

if not test -f "$fixture_file"
    echo "compare_moon_fixture.fish: fixture not found: $fixture_file" >&2
    exit 1
end

# Moon constants (same as conf.d)
set -q __tide_report_moon_PI; or set -g __tide_report_moon_PI (math --scale=max "acos(-1)")
set -q __tide_report_moon_rad; or set -g __tide_report_moon_rad (math --scale=max "$__tide_report_moon_PI / 180")
set -q __tide_report_moon_day_seconds; or set -g __tide_report_moon_day_seconds 86400
set -q __tide_report_moon_J1970; or set -g __tide_report_moon_J1970 2440588
set -q __tide_report_moon_J2000; or set -g __tide_report_moon_J2000 2451545
set -q __tide_report_moon_obliquity; or set -g __tide_report_moon_obliquity (math --scale=max "$__tide_report_moon_rad * 23.4397")

source "$repo_root/functions/_tide_report_moon_math.fish"

set -l total 0
set -l phase_outside 0
set -l illum_within_1 0
set -l illum_within_2 0
set -l illum_outside_2 0
set -l worst

for entry in (jq -c '.samples[]' "$fixture_file" 2>/dev/null)
    set total (math $total + 1)
    set -l unix (string trim (echo "$entry" | jq -r '.unix' | head -n1))
    set -l fixture_illum (string trim (echo "$entry" | jq -r '.illumination' | head -n1))
    set -l fixture_phase_fraction (string trim (echo "$entry" | jq -r '.phase_fraction' | head -n1))
    set -l our_illum (__tide_report_moon_illumination_from_unix $unix 2>/dev/null)
    set -l our_phase_fraction (__tide_report_moon_phase_fraction_from_unix $unix 2>/dev/null)
    if test -z "$our_illum"
        set our_illum -999
    end
    if test -z "$our_phase_fraction"
        set our_phase_fraction -999
    end

    set -l diff (math "abs($our_illum - $fixture_illum)")
    set -l phase_diff (math "abs($our_phase_fraction - $fixture_phase_fraction)")
    if test (math "$phase_diff - 0.000001") -gt 0
        set phase_outside (math $phase_outside + 1)
    end
    if test (math "floor($diff)") -le 1
        set illum_within_1 (math $illum_within_1 + 1)
    else if test (math "floor($diff)") -le 2
        set illum_within_2 (math $illum_within_2 + 1)
    else
        set illum_outside_2 (math $illum_outside_2 + 1)
    end
    set worst $worst "$total|$unix|$fixture_illum|$our_illum|$diff|$fixture_phase_fraction|$our_phase_fraction|$phase_diff"
end

echo "Moon comparison (our model vs canonical SunCalc fixture)"
echo "Fixture: $fixture_file"
echo ""
echo "Summary: $total entries"
echo "  Illumination within ±1%:  $illum_within_1"
echo "  Illumination within ±2%:  $illum_within_2"
echo "  Illumination outside ±2%: $illum_outside_2"
echo "  Phase fraction outside 1e-6: $phase_outside"
echo ""

if test $illum_outside_2 -gt 0; or test $phase_outside -gt 0
    echo "Worst differences (entry | unix | fixture% | our% | illum_diff | fixture_phase | our_phase | phase_diff):"
    for line in $worst
        set -l parts (string split "|" -- $line)
        set -l illum_diff (math "floor($parts[5])")
        set -l phase_diff_flag (test (math "$parts[8] - 0.000001") -gt 0; and echo 1; or echo 0)
        if test $illum_diff -gt 2; or test $phase_diff_flag -eq 1
            echo "  entry $parts[1]  unix=$parts[2]  fixture=$parts[3]%  our=$parts[4]%  illum_diff=$parts[5]%  fixture_phase=$parts[6]  our_phase=$parts[7]  phase_diff=$parts[8]"
        end
    end
end
