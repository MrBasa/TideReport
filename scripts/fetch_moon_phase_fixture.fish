#!/usr/bin/env fish
## Fetch moon phase reference fixture from ViewBits for TideReport tests.
##
## ViewBits: https://api.viewbits.com/v1/moonphase
## - 7 days per request via ?startdate=YYYY-MM-DD. No API key.
## - Rate limit: 5 requests per 30 seconds; script sleeps 60s between requests to avoid it.
##
## Run from repo root. Overwrites test/fixtures/moon_phase_reference.json with ~50 entries
## (unix, phase, illumination) from ViewBits. Requires: curl, jq.

set -l script_dir (path dirname (status filename))
set -l repo_root (path dirname $script_dir)
set -l out_file "$repo_root/test/fixtures/moon_phase_reference.json"
set -l base_url "https://api.viewbits.com/v1/moonphase"
set -l timeout 60
set -l retries 3
set -l retry_delay 3
set -l between_request_delay 60
set -l max_entries 50

set -l ua "TideReport/moon-fixture-scraper"
set -q tide_report_user_agent; and set ua $tide_report_user_agent
set -l tmp_file (command mktemp)
set -l curl_stderr (command mktemp)
set -l request_num 0
set -l total_requests 8

echo "Fetching moon phase fixture from ViewBits ($total_requests requests, ~$max_entries entries)..." >&2

set -l base_sec (date +%s)
# Format Unix timestamp as YYYY-MM-DD (GNU date -d @epoch or BSD date -r epoch)
function _format_date --argument-names epoch
    set -l d (command date -d @$epoch +%Y-%m-%d 2>/dev/null)
    test -n "$d"; and echo $d; or command date -r $epoch +%Y-%m-%d 2>/dev/null
end
for i in 0 7 14 21 28 35 42 49
    set request_num (math $request_num + 1)
    set -l start_sec (math "$base_sec + $i * 86400")
    set -l start_date (_format_date $start_sec)
    set -l url "$base_url?startdate=$start_date"
    set -l ok 0
    for r in (seq 1 $retries)
        echo "  [$request_num/$total_requests] startdate=$start_date" (test $r -gt 1; and echo " (retry $r/$retries)"; or echo "") "..." >&2
        set -l data (curl -s -A "$ua" --max-time $timeout "$url" 2>$curl_stderr)
        set -l curl_status $status
        set -l curl_err (command cat $curl_stderr 2>/dev/null)
        command rm -f $curl_stderr

        if test $curl_status -ne 0
            echo "    curl failed (exit $curl_status): $curl_err" >&2
        else if test -z "$data"
            echo "    curl returned empty response" >&2
        else if string match -q '{"info":*' "$data"
            echo "    API response: $(echo $data | jq -r '.info // .' 2>/dev/null)" >&2
        else
            set -l parsed (echo "$data" | jq -c '[.[] | {unix: .timestamp, phase: .phase, illumination: ((.illumination | gsub("%"; "") | tonumber) // 0)}]' 2>/dev/null)
            if test $status -ne 0; or test -z "$parsed"
                echo "    jq parse failed (response may not be JSON array)" >&2
            else
                echo "$parsed" >> $tmp_file
                set -l n (echo "$parsed" | jq 'length' 2>/dev/null)
                echo "    OK ($n entries)" >&2
                set ok 1
                break
            end
        end
        test $r -lt $retries; and sleep $retry_delay
    end
    if test $ok -eq 0
        echo "fetch_moon_phase_fixture.fish: failed to fetch startdate=$start_date after $retries attempts" >&2
        command rm -f $tmp_file
        exit 1
    end
    test $i -lt 49; and echo "  waiting $between_request_delay s (rate limit)..." >&2; and sleep $between_request_delay
end

echo "Merging and writing fixture..." >&2
jq -s 'add | sort_by(.unix) | unique_by(.unix) | .[0:'$max_entries']' $tmp_file > $out_file
set -l jq_status $status
command rm -f $tmp_file
if test $jq_status -ne 0
    echo "fetch_moon_phase_fixture.fish: jq merge failed" >&2
    exit 1
end

set -l count (jq 'length' $out_file)
set -l first_unix (jq -r '.[0].unix' $out_file)
set -l last_unix (jq -r '.[-1].unix' $out_file)
set -l first_date (_format_date $first_unix)
set -l last_date (_format_date $last_unix)
echo "Done. Wrote $count entries to $out_file (range: $first_date to $last_date)" >&2
