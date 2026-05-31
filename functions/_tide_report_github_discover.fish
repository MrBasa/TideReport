## TideReport :: Discover git repo metadata without subprocesses (used by github context)

function __tide_report_github_origin_from_config --description "Read remote.origin.url from git config file without invoking git" --argument-names git_dir
    set -l config_file "$git_dir/config"
    test -f "$config_file"; or return 1

    set -l in_origin false
    set -l origin_section (echo '[remote "origin"]')
    for line in (cat "$config_file")
        set line (string trim -- "$line")
        test -n "$line"; or continue
        string match -qr '^\s*#' -- "$line"; and continue

        if test "$line" = "$origin_section"
            set in_origin true
            continue
        end
        if string match -qr '^\[' -- "$line"
            set in_origin false
            continue
        end
        if $in_origin; and string match -qr '^url\s*=' -- "$line"
            string replace -r '^url\s*=\s*' '' -- "$line" | string trim
            return 0
        end
    end
    return 1
end

function __tide_report_github_parse_dot_git_file --description "Resolve worktree .git file to repo_root and git_dir" --argument-names dot_git_path
    test -f "$dot_git_path"; or return 1
    set -l repo_root (path dirname "$dot_git_path")
    set -l first_line ""
    read -l first_line < "$dot_git_path"
    set first_line (string trim -- "$first_line")
    if not string match -qr '^gitdir:\s*(.+)$' -- "$first_line"
        return 1
    end
    set -l git_dir (string trim -- (string replace -r '^gitdir:\s*' '' -- "$first_line"))
    if not string match -q '/*' -- "$git_dir"
        set git_dir (path normalize "$repo_root/$git_dir")
    else
        set git_dir (path normalize "$git_dir")
    end
    test -d "$git_dir"; or test -f "$git_dir/config"; or return 1
    printf "%s\n" (path normalize "$repo_root") "$git_dir"
end

function __tide_report_github_discover_repo --description "Find repo_root and git_dir by reading .git files (no git subprocess)" --argument-names start_dir
    set -q start_dir[1]; or set start_dir "$PWD"
    set -l dir (path resolve "$start_dir" 2>/dev/null | string collect)
    test -n "$dir"; or set dir (path normalize "$start_dir")

    if set -q GIT_DIR; and string length -q -- "$GIT_DIR"
        set -l git_dir "$GIT_DIR"
        if not string match -q '/*' -- "$git_dir"
            set git_dir (path normalize "$dir/$GIT_DIR")
        else
            set git_dir (path normalize "$git_dir")
        end
        set -l repo_root "$dir"
        if string match -q '*/.git' -- "$git_dir"
            set repo_root (path dirname "$git_dir")
        end
        test -f "$git_dir/config"; or test -f "$git_dir/HEAD"; or return 1
        printf "%s\n" (path normalize "$repo_root") "$git_dir"
        return 0
    end

    while true
        set -l dot_git "$dir/.git"
        if test -f "$dot_git"
            set -l parsed (__tide_report_github_parse_dot_git_file "$dot_git")
            test (count $parsed) -ge 2; and printf "%s\n" $parsed[1] $parsed[2]
            return $status
        else if test -d "$dot_git"
            printf "%s\n" (path normalize "$dir") (path normalize "$dot_git")
            return 0
        end
        set -l parent (path dirname "$dir")
        test "$parent" = "$dir"; and break
        set dir "$parent"
    end
    return 1
end

function __tide_report_github_context_resolve --description "Resolve repo_root, git_dir, and origin URL; prefer .git file reads" --argument-names start_dir
    set -l repo_root ""
    set -l git_dir ""
    set -l remote_url ""

    set -l discovered (__tide_report_github_discover_repo "$start_dir")
    if test (count $discovered) -ge 2
        set repo_root $discovered[1]
        set git_dir $discovered[2]
        set remote_url (__tide_report_github_origin_from_config "$git_dir" | string collect)
    end

    if test -z "$repo_root"
        set repo_root (command git rev-parse --show-toplevel 2>/dev/null)
        test -n "$repo_root"; or return 1
        set repo_root (path resolve "$repo_root" 2>/dev/null | string collect)
        test -n "$repo_root"; or set repo_root (path normalize "$repo_root")
    end

    if test -z "$git_dir"
        set git_dir (command git rev-parse --git-dir 2>/dev/null)
        test -n "$git_dir"; or return 1
        if not string match -q '/*' -- "$git_dir"
            set -q start_dir[1]; or set start_dir "$PWD"
            set git_dir (path normalize "$start_dir/$git_dir")
        else
            set git_dir (path normalize "$git_dir")
        end
    end

    if test -z "$remote_url"
        set remote_url (command git config --get remote.origin.url 2>/dev/null)
    end
    test -n "$remote_url"; or return 1

    printf "%s\n" "$repo_root" "$git_dir" "$remote_url"
end
