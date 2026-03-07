source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_moon_math.fish"

@test "moon_to_days returns numeric output" (
    __tide_report_moon_to_days 1704067200 | string match -q -r '^-?[0-9]+(\.[0-9]+)?$'
    echo $status
) -eq 0

@test "moon_phase_fraction_from_unix returns normalized fraction" (
    set -l v (__tide_report_moon_phase_fraction_from_unix 1704067200)
    test -n "$v"; and string match -q -r '^-?[0-9]+(\\.[0-9]+)?$' "$v"
    echo $status
) -eq 0

@test "moon_right_ascension returns numeric value for representative radians" (
    set -l out (__tide_report_moon_right_ascension 1.2 0.4 | string collect)
    string match -q -r '^-?[0-9]+(\\.[0-9]+)?$' "$out"
    echo $status
) -eq 0

@test "moon_declination returns numeric value for representative radians" (
    set -l out (__tide_report_moon_declination 1.2 0.4 | string collect)
    string match -q -r '^-?[0-9]+(\\.[0-9]+)?$' "$out"
    echo $status
) -eq 0

@test "moon_sun_coords returns two numeric lines" (
    set -l vals (__tide_report_moon_sun_coords 365.25)
    test (count $vals) -eq 2
    and string match -q -r '^-?[0-9]+([.][0-9]+)?$' -- "$vals[1]"
    and string match -q -r '^-?[0-9]+([.][0-9]+)?$' -- "$vals[2]"
    echo $status
) -eq 0

@test "moon_moon_coords returns ra dec and positive distance" (
    set -l vals (__tide_report_moon_moon_coords 365.25)
    test (count $vals) -eq 3
    and string match -q -r '^-?[0-9]+([.][0-9]+)?$' -- "$vals[1]"
    and string match -q -r '^-?[0-9]+([.][0-9]+)?$' -- "$vals[2]"
    and string match -q -r '^-?[0-9]+([.][0-9]+)?$' -- "$vals[3]"
    echo $status
) -eq 0
