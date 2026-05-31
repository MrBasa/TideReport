source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_lock_helpers.fish"

set -l tmp (mktemp -d)
set -g HOME "$tmp/home"
mkdir -p "$HOME/.cache/tide-report/locks"

function __tide_report_test_lock_root
    echo "$HOME/.cache/tide-report/locks"
end

@test "lock_acquire succeeds when lock is absent" (
    set -l now (command date +%s)
    __tide_report_lock_acquire test_lock "$now" 120
    echo $status
) -eq 0

@test "lock_acquire fails when fresh lock is held" (
    set -l now (command date +%s)
    __tide_report_lock_acquire held_lock "$now" 120
    __tide_report_lock_acquire held_lock "$now" 120
    set -l st $status
    __tide_report_lock_release held_lock
    echo $st
) -eq 1

@test "lock_acquire recovers stale lock after ttl" (
    set -l now (command date +%s)
    set -l lock_dir (__tide_report_lock_path stale_lock)
    mkdir -p "$lock_dir"
    set -l stale_ts (math $now - 200)
    printf '%s\n' "$stale_ts" > "$lock_dir/ts"
    __tide_report_lock_acquire stale_lock "$now" 120
    set -l st $status
    __tide_report_lock_release stale_lock
    echo $st
) -eq 0

@test "lock_release removes lock directory" (
    set -l now (command date +%s)
    __tide_report_lock_acquire release_lock "$now" 120
    __tide_report_lock_release release_lock
    test -d (__tide_report_lock_path release_lock); and echo 1; or echo 0
) -eq 0

command rm -rf "$tmp"
