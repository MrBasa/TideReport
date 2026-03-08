#!/usr/bin/env fish
## Generate moon phase reference fixture from canonical SunCalc equations.
##
## Historical note: this script previously fetched wttr.in. That source is intentionally
## retired for test fixtures because of flaky availability and provider discrepancies.
##
## Usage: fish scripts/fetch_moon_phase_fixture.fish
## Output: test/fixtures/moon/suncalc_reference.json

set -l script_dir (path dirname (status filename))
set -l generator "$script_dir/generate_moon_suncalc_fixture.mjs"

if not command -sq node
    echo "fetch_moon_phase_fixture.fish: node is required to generate the SunCalc fixture" >&2
    exit 1
end

if not test -f "$generator"
    echo "fetch_moon_phase_fixture.fish: missing generator script: $generator" >&2
    exit 1
end

node "$generator"
exit $status
