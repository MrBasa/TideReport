## Local moon math vs canonical SunCalc fixture (no network).
## This test is deterministic and does not depend on external providers.
## Compare at exact Unix instants from fixture (UTC absolute timestamps).

source (dirname (dirname (status filename)))/helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_provider_moon_local.fish"

set -l fixture_file "$REPO_ROOT/test/fixtures/moon/suncalc_reference.json"
set -l phase_tolerance 0.000001
set -l illum_tolerance 0.001
set -l count 0
set -l failed 0
if not test -f "$fixture_file"
    echo "Fixture missing: $fixture_file (run scripts/generate_moon_suncalc_fixture.mjs)" >&2
    set failed 1
else
    for entry in (jq -c '.samples[]' "$fixture_file" 2>/dev/null)
        set count (math $count + 1)
        set -l unix (string trim (echo "$entry" | jq -r '.unix' | head -n1))
        set -l expected_phase (string trim (echo "$entry" | jq -r '.phase' | head -n1))
        set -l expected_fraction (string trim (echo "$entry" | jq -r '.phase_fraction' | head -n1))
        set -l expected_illum (string trim (echo "$entry" | jq -r '.illumination' | head -n1))

        set -l got_phase (__tide_report_moon_phase_from_unix $unix | string collect)
        set -l got_fraction (__tide_report_moon_phase_fraction_from_unix $unix | string collect)
        set -l got_illum (__tide_report_moon_illumination_from_unix $unix | string collect)
        set -l fraction_diff (math "abs($got_fraction - $expected_fraction)")
        set -l illum_diff (math "abs($got_illum - $expected_illum)")

        if test "$got_phase" != "$expected_phase"
            echo "Fixture entry $count (unix $unix): expected phase \"$expected_phase\", got \"$got_phase\"" >&2
            set failed (math $failed + 1)
            continue
        end

        if test (math "$fraction_diff - $phase_tolerance") -gt 0
            echo "Fixture entry $count (unix $unix): phase_fraction diff $fraction_diff exceeds $phase_tolerance" >&2
            set failed (math $failed + 1)
            continue
        end

        if test (math "$illum_diff - $illum_tolerance") -gt 0
            echo "Fixture entry $count (unix $unix): illumination diff $illum_diff exceeds $illum_tolerance" >&2
            set failed (math $failed + 1)
        end
    end
    test $count -eq 0; and set failed 1
end

@test "local moon model matches reference fixture for all entries" (
    test $failed -eq 0
    echo $status
) -eq 0
