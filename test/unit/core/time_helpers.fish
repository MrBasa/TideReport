source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_time_helpers.fish"

@test "iso8601_to_unix returns numeric epoch for ISO date-time" (
    set -l out (__tide_report_iso8601_to_unix "2027-01-01T12:00" | string collect)
    string match -q -r '^[0-9]+$' "$out"; and test "$out" -gt 0
    echo $status
) -eq 0

@test "iso8601_to_unix matches GNU local parse for timezone-less ISO input" (
    set -l gnu (__tide_report_gnu_date_cmd | string collect)
    test -n "$gnu"; or begin
        echo 0
        exit 0
    end
    set -l expected ($gnu -d "2027-01-01T12:00" +%s 2>/dev/null | string collect)
    set -l got (__tide_report_iso8601_to_unix "2027-01-01T12:00" | string collect)
    test "$got" = "$expected"
    echo $status
) -eq 0
