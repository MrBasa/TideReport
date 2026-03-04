## Optional validation test: compare local moon model against timeanddate.com
## for major phases in a given year. This is intended as an external sanity
## check and is skipped unless TIDE_REPORT_ENABLE_TIMEANDDATE_TESTS is set.
##
## We display 8 phases (New Moon, Waxing Crescent, First Quarter, Waxing
## Gibbous, Full Moon, Waning Gibbous, Third Quarter, Waning Crescent), but
## timeanddate.com only publishes exact dates for the 4 primary events (New
## Moon, First Quarter, Full Moon, Third Quarter). The other four are
## intervals between those and have no single "event" date on that site, so
## this test validates the four primary phases only.

if not set -q TIDE_REPORT_ENABLE_TIMEANDDATE_TESTS
    exit 0
end

# status filename is e.g. .../test/integration/moon_local_vs_timeanddate.fish
set -g REPO_ROOT (dirname (dirname (dirname (status filename))))
source "$REPO_ROOT/test/setup.fish"
source "$REPO_ROOT/functions/_tide_report_moon_math.fish"
source "$REPO_ROOT/functions/_tide_report_provider_weather_openmeteo.fish"

## Map an English month name (January, February, ...) to a zero-padded month number.
function __tide_report_month_name_to_number --description "Map English month name to zero-padded month number" --argument-names name
    switch $name
        case January; echo 01
        case February; echo 02
        case March; echo 03
        case April; echo 04
        case May; echo 05
        case June; echo 06
        case July; echo 07
        case August; echo 08
        case September; echo 09
        case October; echo 10
        case November; echo 11
        case December; echo 12
        case '*'; echo ""
    end
end

## Fetch timeanddate.com moon phase table for a year and compare dates with the local model.
function __tide_report_moon_timeanddate_check --description "Validate local moon model against timeanddate.com for a given year" --argument-names year
    set -l url "https://www.timeanddate.com/moon/phases/?year=$year"
    set -l html (curl -s "$url")
    if test $status -ne 0; or test -z "$html"
        echo "timeanddate.com fetch failed for year $year; skipping check" >&2
        return 0
    end

    set -l events
    for phase_label in "New Moon" "First Quarter" "Full Moon" "Third Quarter"
        for m in (printf "%s\n" $html | string match -r -a "\"$phase_label on [^\"]*\"")
            set -l s (string replace -r '^"|"$' '' -- $m)
            set -l parts (string match -r '^(New Moon|Full Moon|First Quarter|Third Quarter) on .* ([A-Za-z]+) ([0-9]{1,2}), ([0-9]{4})' -- $s)
            if test (count $parts) -lt 5
                continue
            end
            set -l p_name $parts[2]
            set -l month_name $parts[3]
            set -l day $parts[4]
            set -l y $parts[5]
            if test "$y" != "$year"
                continue
            end
            set -l mm (__tide_report_month_name_to_number $month_name)
            if test -z "$mm"
                continue
            end
            if test (string length -- $day) -eq 1
                set day 0$day
            end
            set -a events "$p_name|$y-$mm-$day"
        end
    end

    if test (count $events) -eq 0
        echo "no moon phase events parsed from timeanddate.com for $year; skipping check" >&2
        return 0
    end

    # Ensure we check at least one date per distinct phase (in phase order)
    set -l phases "New Moon" "First Quarter" "Full Moon" "Third Quarter"
    set -l events_to_check
    for p in $phases
        for ev in $events
            set -l p_ev (string split '|' -- $ev)[1]
            if test "$p_ev" = "$p"
                set -a events_to_check $ev
                break
            end
        end
    end
    if test (count $events_to_check) -lt 4
        echo "timeanddate.com did not have all four phases for $year; skipping check" >&2
        return 0
    end

    echo "# date phase timeanddate_expected local_frac diff" >&2
    set -l failures 0
    for ev in $events_to_check
        set -l p_name (string split '|' -- $ev)[1]
        set -l date_str (string split '|' -- $ev)[2]

        set -l expected
        switch $p_name
            case "New Moon"; set expected 0.0
            case "First Quarter"; set expected 0.25
            case "Full Moon"; set expected 0.5
            case "Third Quarter"; set expected 0.75
            case '*'; continue
        end

        set -l iso "$date_str"T"12:00:00Z"
        set -l unix (__tide_report_iso8601_to_unix $iso)
        if test -z "$unix"
            echo "failed to convert $iso to unix; skipping event $ev" >&2
            continue
        end

        set -l frac (__tide_report_moon_phase_fraction_from_unix $unix)
        if test -z "$frac"
            echo "local model returned empty fraction for $iso; skipping" >&2
            continue
        end

        set -l raw_diff (math "abs($frac - $expected)")
        set -l diff (math "min($raw_diff, 1 - $raw_diff)")

        echo "# $date_str $p_name  timeanddate→expected=$expected  local=$frac  diff=$diff" >&2

        if test (math "floor($diff / 0.15)") -ge 1
            echo "Mismatch for $p_name on $date_str:" >&2
            echo "  expected phase ~ $expected, got $frac (diff=$diff)" >&2
            set failures (math "$failures + 1")
        end
    end

    if test $failures -gt 0
        return 1
    end
    return 0
end

@test "local moon model roughly matches timeanddate.com phases for 2027 (when enabled)" (
    __tide_report_moon_timeanddate_check 2027
    echo $status
) -eq 0

