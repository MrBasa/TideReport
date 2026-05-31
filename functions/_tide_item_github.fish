## TideReport :: GitHub Prompt Item
##
## Thin entry point; helpers live in _tide_report_github_*.fish modules.

if not functions -q __tide_report_lock_acquire
    source (status filename | path dirname)/_tide_report_lock_helpers.fish
end
if not functions -q __tide_report_github_path_within
    source (status filename | path dirname)/_tide_report_github_context.fish
end
if not functions -q __tide_report_parse_github
    source (status filename | path dirname)/_tide_report_github_parse.fish
end
if not functions -q __tide_report_fetch_github
    source (status filename | path dirname)/_tide_report_github_fetch.fish
end

function _tide_item_github --description "Displays GitHub stats"
    set -l now (command date +%s)
    set -l context (__tide_report_github_context)
    test (count $context) -ge 6; or return 0

    set -l api_slug $context[1]
    set -l cache_key $context[2]
    set -l cache_dir $context[3]
    set -l cache_file $context[4]
    set -l git_dir $context[6]
    set -l branch (__tide_report_github_branch_from_head "$git_dir" | string collect)
    set -l ci_cache_file (__tide_report_github_ci_cache_file "$cache_dir" "$cache_key" "$branch")
    set -l refresh_seconds $tide_report_github_refresh_seconds
    set -l timeout_sec (math --scale=0 "$tide_report_service_timeout_millis / 1000")
    set -l clean_key (string replace -a -r '[^a-zA-Z0-9_]' '_' "$cache_key")
    set -l ci_lock_var ""
    if test -n "$branch"
        set -l branch_safe (string replace -a -r '[^a-zA-Z0-9_]' '_' "$branch")
        set ci_lock_var "github_ci_"$clean_key"_"$branch_safe
    end

    set -l trigger_fetch false
    set -l trigger_ci_fetch false
    set -l output_valid false
    set -l cached_ci_state none
    if test "$tide_report_github_show_ci" = true; and test -f "$ci_cache_file"
        set cached_ci_state (__tide_report_github_read_ci_state "$ci_cache_file" | string collect)
        test -n "$cached_ci_state"; or set cached_ci_state none
    end
    set -l ci_refresh_seconds (__tide_report_github_ci_effective_refresh "$cached_ci_state" "$ci_lock_var")
    set -q tide_report_github_ci_expire_seconds; or set -l tide_report_github_ci_expire_seconds 180
    set -l ci_age -1
    if test "$tide_report_github_show_ci" = true; and test -f "$ci_cache_file"
        set -l ci_mod (__tide_report_github_file_mtime "$ci_cache_file" | string collect)
        test -n "$ci_mod"; or set ci_mod 0
        set ci_age (math $now - $ci_mod)
    end

    if test -f "$cache_file"
        set -l mod_time (__tide_report_github_file_mtime "$cache_file" | string collect)
        test -n "$mod_time"; or set mod_time 0
        set -l age (math $now - $mod_time)

        if test $age -gt $refresh_seconds
            set trigger_fetch true
        end
        set output_valid true
    else
        set trigger_fetch true
    end

    if test "$tide_report_github_show_ci" = true
        if test -f "$ci_cache_file"
            set -l ci_mod (__tide_report_github_file_mtime "$ci_cache_file" | string collect)
            test -n "$ci_mod"; or set ci_mod 0
            if test (math $now - $ci_mod) -gt $ci_refresh_seconds
                set trigger_ci_fetch true
            end
        else
            set trigger_ci_fetch true
        end
    end

    if test "$trigger_fetch" = true
        set -l lock_var "github_$clean_key"
        if __tide_report_lock_acquire "$lock_var" "$now" 120
            mkdir -p "$cache_dir"
            __tide_report_fetch_github "$api_slug" "$cache_file" "$timeout_sec" "$lock_var" &
            disown 2>/dev/null
        end
    end

    if test "$trigger_ci_fetch" = true; and test -n "$branch"
        if __tide_report_lock_acquire "$ci_lock_var" "$now" 120
            mkdir -p "$cache_dir"
            __tide_report_fetch_github_ci "$api_slug" "$branch" "$ci_cache_file" "$timeout_sec" "$ci_lock_var" &
            disown 2>/dev/null
        end
    end

    set -l ci_fetch_in_flight false
    if test "$tide_report_github_show_ci" = true; and test -n "$ci_lock_var"
        __tide_report_lock_held "$ci_lock_var"; and set ci_fetch_in_flight true
    end

    if test "$output_valid" = true
        set -l ci_display_state none
        if test "$tide_report_github_show_ci" = true
            set ci_display_state (__tide_report_github_ci_display_state "$cached_ci_state" $ci_age $ci_refresh_seconds $tide_report_github_ci_expire_seconds $ci_fetch_in_flight | string collect)
        end
        if test "$tide_report_github_show_ci" = true
            __tide_report_parse_github "$cache_file" - "$ci_cache_file" - "$ci_display_state"
        else
            __tide_report_parse_github "$cache_file"
        end
    else
        set -l unavail (__tide_report_github_unavailable_display | string collect)
        _tide_print_item github (set_color $tide_report_github_unavailable_color)$unavail
    end
end
