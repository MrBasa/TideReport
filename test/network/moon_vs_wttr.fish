## Local moon phase vs reference fixture (no network).
## Fixture built from ViewBits or from local model; see scripts/fetch_moon_phase_fixture.fish.

source (dirname (dirname (status filename)))/helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_provider_moon_local.fish"

set -l fixture_file "$REPO_ROOT/test/fixtures/moon_phase_reference.json"
set -l count 0
set -l failed 0
if not test -f "$fixture_file"
    echo "Fixture missing: $fixture_file (run scripts/fetch_moon_phase_fixture.fish)" >&2
    set failed 1
else
    for entry in (jq -c '.[]' "$fixture_file" 2>/dev/null)
        set count (math $count + 1)
        set -l unix (echo "$entry" | jq -r '.unix')
        set -l expected_phase (echo "$entry" | jq -r '.phase')
        set -l got (__tide_report_moon_phase_from_unix $unix | string collect)
        if test "$got" != "$expected_phase"
            echo "Fixture entry $count (unix $unix): expected \"$expected_phase\", got \"$got\"" >&2
            set failed (math $failed + 1)
        end
    end
    test $count -eq 0; and set failed 1
end

@test "local moon model matches reference fixture for all entries" (
    test $failed -eq 0
    echo $status
) -eq 0
