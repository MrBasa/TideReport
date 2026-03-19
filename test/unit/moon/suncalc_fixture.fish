## Unit test: local moon math vs canonical SunCalc fixture (offline, deterministic).

source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_provider_moon_local.fish"

set -l fixture_file "$REPO_ROOT/test/fixtures/moon/suncalc_reference.json"
set -l phase_tolerance 0.000001
set -l illum_tolerance 0.001
set -l count 0
set -l failed 0
set -l max_phase_diff 0
set -l max_illum_diff 0

if not test -f "$fixture_file"
    echo "Fixture missing: $fixture_file" >&2
    set failed 1
else
    for entry in (jq -c '.samples[]' "$fixture_file" 2>/dev/null)
        set count (math "$count + 1")

        set -l unix (echo "$entry" | jq -r '.unix' | head -n1)
        set -l expected_phase_fraction (echo "$entry" | jq -r '.phase_fraction' | head -n1)
        set -l expected_illumination (echo "$entry" | jq -r '.illumination' | head -n1)
        set -l expected_phase_name (echo "$entry" | jq -r '.phase' | head -n1)

        set -l got_phase_fraction (__tide_report_moon_phase_fraction_from_unix $unix)
        set -l got_illumination (__tide_report_moon_illumination_from_unix $unix)
        set -l got_phase_name (__tide_report_moon_phase_from_unix $unix)

        set -l phase_diff (math "abs($got_phase_fraction - $expected_phase_fraction)")
        set -l illum_diff (math "abs($got_illumination - $expected_illumination)")

        if test (math "$phase_diff - $max_phase_diff") -gt 0
            set max_phase_diff $phase_diff
        end

        if test (math "$illum_diff - $max_illum_diff") -gt 0
            set max_illum_diff $illum_diff
        end

        if test "$got_phase_name" != "$expected_phase_name"
            echo "Fixture entry $count (unix $unix): expected phase '$expected_phase_name', got '$got_phase_name'" >&2
            set failed (math "$failed + 1")
            continue
        end

        if test (math "$phase_diff - $phase_tolerance") -gt 0
            echo "Fixture entry $count (unix $unix): phase_fraction diff $phase_diff exceeds $phase_tolerance" >&2
            set failed (math "$failed + 1")
            continue
        end

        if test (math "$illum_diff - $illum_tolerance") -gt 0
            echo "Fixture entry $count (unix $unix): illumination diff $illum_diff exceeds $illum_tolerance" >&2
            set failed (math "$failed + 1")
        end
    end
end

if test $count -eq 0
    echo "No samples found in fixture: $fixture_file" >&2
    set failed (math "$failed + 1")
end

@test "local moon math matches canonical SunCalc fixture" (
    test $failed -eq 0
    echo $status
) -eq 0
