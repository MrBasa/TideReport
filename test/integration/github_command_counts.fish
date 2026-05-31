source (dirname (dirname (status filename)))/helpers/setup.fish

set -g __tide_report_test_real_git (command -s git)
set -g __tide_report_test_real_jq (command -s jq)

function __tide_report_test_write_exec_wrapper --argument-names wrapper_path label real_path log_path
    printf '%s\n' \
        '#!/usr/bin/env bash' \
        'echo "'$label' $*" >> "'$log_path'"' \
        'exec "'$real_path'" "$@"' > "$wrapper_path"
    chmod +x "$wrapper_path"
end

function __tide_report_test_reset_github_context --description "Clear session GitHub context between tests"
    set -e __tide_report_github_context_repo_root 2>/dev/null
    set -e __tide_report_github_context_values 2>/dev/null
    set -e __tide_report_github_auth_ok 2>/dev/null
end

function __tide_report_test_seed_github_repo --argument-names tmp_dir
    __tide_report_test_reset_github_context
    mkdir -p "$tmp_dir/home/.config/fish" "$tmp_dir/home/.cache/tide-report/github" "$tmp_dir/bin" "$tmp_dir/repo"

    __tide_report_test_write_exec_wrapper "$tmp_dir/bin/git" git "$__tide_report_test_real_git" "$tmp_dir/calls.log"
    __tide_report_test_write_exec_wrapper "$tmp_dir/bin/jq" jq "$__tide_report_test_real_jq" "$tmp_dir/calls.log"

    cp "$REPO_ROOT/test/fixtures/github/repo.json" "$tmp_dir/home/.cache/tide-report/github/MrBasa-TideReport.json"
    printf '%s\n' '42 3 10 2 1' > "$tmp_dir/home/.cache/tide-report/github/MrBasa-TideReport.json.stats"
    cd "$tmp_dir/repo"
    command "$__tide_report_test_real_git" init >/dev/null 2>&1
    command "$__tide_report_test_real_git" remote add origin "https://github.com/MrBasa/TideReport.git"
    set -l branch (command "$__tide_report_test_real_git" branch --show-current 2>/dev/null | string collect)
    test -n "$branch"; or set branch detached
    set -l branch_safe (string replace -a -r '[^a-zA-Z0-9._-]' '_' "$branch")
    set -l ci_base "$tmp_dir/home/.cache/tide-report/github/MrBasa-TideReport-$branch_safe-ci.json"
    command rm -f "$tmp_dir/home/.cache/tide-report/github/MrBasa-TideReport-main-ci.json" "$tmp_dir/home/.cache/tide-report/github/MrBasa-TideReport-main-ci.json.state" 2>/dev/null
    printf '%s\n' '[{"status":"completed","conclusion":"success"}]' > "$ci_base"
    printf '%s\n' pass > "$ci_base.state"
    printf '%s\n' '[{"status":"completed","conclusion":"failure"}]' > "$tmp_dir/home/.cache/tide-report/github/MrBasa-TideReport-feature_demo-ci.json"
    printf '%s\n' fail > "$tmp_dir/home/.cache/tide-report/github/MrBasa-TideReport-feature_demo-ci.json.state"
    cd "$REPO_ROOT"
end

@test "github first context resolution performs no git or jq calls" (
    set -l tmp (mktemp -d)
    __tide_report_test_seed_github_repo "$tmp"

    set -lx HOME "$tmp/home"
    set -lx XDG_CONFIG_HOME "$tmp/home/.config"
    set -lx PATH "$tmp/bin" $PATH
    cd "$REPO_ROOT"
    source test/helpers/setup.fish
    cd "$tmp/repo"
    set -g TIDE_REPORT_TEST 1
    set -g tide_report_github_show_ci false
    set -g tide_report_github_refresh_seconds 99999

    __tide_report_test_reset_print_capture
    _tide_item_github >/dev/null

    set -l ok 1
    test -s "$tmp/calls.log" && set ok 0
    cd "$REPO_ROOT"
    command rm -rf "$tmp"
    echo $ok
) -eq 1

@test "github warm cache second render performs no git or jq calls" (
    set -l tmp (mktemp -d)
    __tide_report_test_seed_github_repo "$tmp"

    set -lx HOME "$tmp/home"
    set -lx XDG_CONFIG_HOME "$tmp/home/.config"
    set -lx PATH "$tmp/bin" $PATH
    cd "$REPO_ROOT"
    source test/helpers/setup.fish
    cd "$tmp/repo"
    set -g TIDE_REPORT_TEST 1
    set -g tide_report_github_show_ci true
    set -g tide_report_github_refresh_seconds 99999
    set -g tide_report_github_ci_refresh_seconds 99999

    __tide_report_test_reset_print_capture
    _tide_item_github >/dev/null
    printf '' > "$tmp/calls.log"
    __tide_report_test_reset_print_capture
    _tide_item_github >/dev/null

    set -l ok 1
    test -s "$tmp/calls.log" && set ok 0
    cd "$REPO_ROOT"
    command rm -rf "$tmp"
    echo $ok
) -eq 1

@test "github context stays cached after old 2 second ttl window" (
    set -l tmp (mktemp -d)
    __tide_report_test_seed_github_repo "$tmp"

    set -lx HOME "$tmp/home"
    set -lx XDG_CONFIG_HOME "$tmp/home/.config"
    set -lx PATH "$tmp/bin" $PATH
    cd "$REPO_ROOT"
    source test/helpers/setup.fish
    cd "$tmp/repo"
    set -g TIDE_REPORT_TEST 1
    set -g tide_report_github_show_ci true
    set -g tide_report_github_refresh_seconds 99999
    set -g tide_report_github_ci_refresh_seconds 99999

    __tide_report_test_reset_print_capture
    _tide_item_github >/dev/null
    sleep 3
    printf '' > "$tmp/calls.log"
    __tide_report_test_reset_print_capture
    _tide_item_github >/dev/null

    set -l ok 1
    test -s "$tmp/calls.log" && set ok 0
    cd "$REPO_ROOT"
    command rm -rf "$tmp"
    echo $ok
) -eq 1

@test "github branch changes use HEAD file and switch ci cache without git calls" (
    set -l tmp (mktemp -d)
    __tide_report_test_seed_github_repo "$tmp"

    set -lx HOME "$tmp/home"
    set -lx XDG_CONFIG_HOME "$tmp/home/.config"
    set -lx PATH "$tmp/bin" $PATH
    cd "$REPO_ROOT"
    source test/helpers/setup.fish
    cd "$tmp/repo"
    set -g TIDE_REPORT_TEST 1
    set -g tide_report_github_show_ci true
    set -g tide_report_github_refresh_seconds 99999
    set -g tide_report_github_ci_refresh_seconds 99999

    __tide_report_test_reset_print_capture
    _tide_item_github >/dev/null
    printf '%s\n' 'ref: refs/heads/feature/demo' > "$tmp/repo/.git/HEAD"
    printf '' > "$tmp/calls.log"
    __tide_report_test_reset_print_capture
    _tide_item_github >/dev/null

    set -l ok 1
    test -s "$tmp/calls.log" && set ok 0
    string match -q '*✗*' "$_tide_print_item_last_argv[2]" || set ok 0
    cd "$REPO_ROOT"
    command rm -rf "$tmp"
    echo $ok
) -eq 1

set -e __tide_report_test_real_git
set -e __tide_report_test_real_jq
