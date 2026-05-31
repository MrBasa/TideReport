## TideReport :: GitHub parse and render helpers

function __tide_report_github_stats_from_json --description "Extract compact stats line from repo JSON" --argument-names cache_file
    command jq -r '[.stargazerCount,.forkCount,.watchers.totalCount,.issues.totalCount,.pullRequests.totalCount]|join(" ")' "$cache_file" 2>/dev/null
end

function __tide_report_github_read_stats_line --description "Read GitHub stats from sidecar or legacy JSON fallback" --argument-names cache_file
    if not functions -q __tide_report_github_stats_file
        source (status filename | path dirname)/_tide_report_github_context.fish
    end
    set -l stats_file (__tide_report_github_stats_file "$cache_file")
    if test -f "$stats_file"
        set -l line ""
        read -l line < "$stats_file"
        if __tide_report_github_stats_line_valid "$line"
            echo "$line"
            return 0
        end
    end

    set -l line (__tide_report_github_stats_from_json "$cache_file")
    if __tide_report_github_stats_line_valid "$line"
        echo "$line"
        return 0
    end

    return 1
end

function __tide_report_github_ci_state_from_json --description "Normalize GitHub CI state from legacy JSON cache" --argument-names ci_cache_file
    set -l first (command jq -r 'if length > 0 then (.[0] | "\(.status) \(.conclusion)") else "" end' "$ci_cache_file" 2>/dev/null)
    if test -z "$first"; or test "$first" = "null null"
        echo none
        return 0
    end

    set -l parts (string split " " "$first")
    set -l run_status "$parts[1]"
    set -l conclusion "$parts[2]"
    if test "$run_status" = "completed"
        if test "$conclusion" = "success"
            echo pass
        else
            echo fail
        end
    else
        echo pending
    end
end

function __tide_report_github_read_ci_state --description "Read normalized GitHub CI state from sidecar or legacy JSON fallback" --argument-names ci_cache_file
    if not functions -q __tide_report_github_state_file
        source (status filename | path dirname)/_tide_report_github_context.fish
    end
    set -l state_file (__tide_report_github_state_file "$ci_cache_file")
    if test -f "$state_file"
        set -l ci_state ""
        read -l ci_state < "$state_file"
        if __tide_report_github_ci_state_valid "$ci_state"
            echo "$ci_state"
            return 0
        end
    end

    test -f "$ci_cache_file"; or return 1
    set -l ci_state (__tide_report_github_ci_state_from_json "$ci_cache_file")
    if __tide_report_github_ci_state_valid "$ci_state"
        echo "$ci_state"
        return 0
    end

    return 1
end

function __tide_report_render_github --description "Render GitHub segment from stars/forks/watchers/issues/prs and ci_state (pass|fail|pending|none)" --argument-names stars forks watchers issues prs ci_state
    set -q stars || set stars 0
    set -q forks || set forks 0
    set -q watchers || set watchers 0
    set -q issues || set issues 0
    set -q prs || set prs 0
    set -q ci_state || set ci_state none

    set -q tide_report_github_icon; or set -l tide_report_github_icon ""
    set -q tide_report_github_icon_stars; or set -l tide_report_github_icon_stars "★"
    set -q tide_report_github_icon_forks; or set -l tide_report_github_icon_forks "⑂"
    set -q tide_report_github_icon_watchers; or set -l tide_report_github_icon_watchers ""
    set -q tide_report_github_icon_issues; or set -l tide_report_github_icon_issues "!"
    set -q tide_report_github_icon_prs; or set -l tide_report_github_icon_prs "PR"
    set -q tide_report_github_color_stars; or set -l tide_report_github_color_stars "yellow"
    set -q tide_report_github_color_forks; or set -l tide_report_github_color_forks "yellow"
    set -q tide_report_github_color_watchers; or set -l tide_report_github_color_watchers "yellow"
    set -q tide_report_github_color_issues; or set -l tide_report_github_color_issues "yellow"
    set -q tide_report_github_color_prs; or set -l tide_report_github_color_prs "yellow"

    set -l icon "$tide_report_github_icon"
    test -z "$icon"; and set icon ""
    set -l output "$icon"
    if not set -q TIDE_REPORT_TEST
        test "$stars" != 0 && set output "$output"(set_color $tide_report_github_color_stars)" $tide_report_github_icon_stars$stars"
        test "$forks" != 0 && set output "$output"(set_color $tide_report_github_color_forks)" $tide_report_github_icon_forks$forks"
        test "$watchers" != 0 && set output "$output"(set_color $tide_report_github_color_watchers)" $tide_report_github_icon_watchers$watchers"
        test "$issues" != 0 && set output "$output"(set_color $tide_report_github_color_issues)" $tide_report_github_icon_issues$issues"
        test "$prs" != 0 && set output "$output"(set_color $tide_report_github_color_prs)" $tide_report_github_icon_prs$prs"
    else
        test "$stars" != 0 && set output "$output $tide_report_github_icon_stars$stars"
        test "$forks" != 0 && set output "$output $tide_report_github_icon_forks$forks"
        test "$watchers" != 0 && set output "$output $tide_report_github_icon_watchers$watchers"
        test "$issues" != 0 && set output "$output $tide_report_github_icon_issues$issues"
        test "$prs" != 0 && set output "$output $tide_report_github_icon_prs$prs"
    end

    if test "$tide_report_github_show_ci" = true; and test -n "$ci_state"; and test "$ci_state" != "none"
        set -q tide_report_github_icon_ci_pass; or set -l tide_report_github_icon_ci_pass "✔"
        set -q tide_report_github_icon_ci_fail; or set -l tide_report_github_icon_ci_fail "✗"
        set -q tide_report_github_icon_ci_pending; or set -l tide_report_github_icon_ci_pending "⏳"
        set -q tide_report_github_color_ci_pass; or set -l tide_report_github_color_ci_pass "green"
        set -q tide_report_github_color_ci_fail; or set -l tide_report_github_color_ci_fail "red"
        set -q tide_report_github_color_ci_pending; or set -l tide_report_github_color_ci_pending "yellow"
        if not set -q TIDE_REPORT_TEST
            switch "$ci_state"
                case pass
                    set output "$output "(set_color $tide_report_github_color_ci_pass)$tide_report_github_icon_ci_pass
                case fail
                    set output "$output "(set_color $tide_report_github_color_ci_fail)$tide_report_github_icon_ci_fail
                case "*"
                    set output "$output "(set_color $tide_report_github_color_ci_pending)$tide_report_github_icon_ci_pending
            end
        else
            switch "$ci_state"
                case pass
                    set output "$output $tide_report_github_icon_ci_pass"
                case fail
                    set output "$output $tide_report_github_icon_ci_fail"
                case "*"
                    set output "$output $tide_report_github_icon_ci_pending"
            end
        end
    end

    if test -n "$output"
        string trim "$output"
    end
end

function __tide_report_parse_github --description "Parse cached GitHub repo stats JSON and print a formatted segment" --argument-names cache_file stats_line ci_cache_file ci_fetch_in_flight ci_display_state
    if not functions -q __tide_report_github_unavailable_display
        source (status filename | path dirname)/_tide_report_github_context.fish
    end
    set -l line ""
    if set -q stats_line[1]; and test -n "$stats_line"; and test "$stats_line" != "-"
        set line $stats_line
    else
        set line (__tide_report_github_read_stats_line "$cache_file" | string collect)
    end
    if test "$ci_cache_file" = "-"; or not set -q ci_cache_file[1]
        set ci_cache_file ""
    end
    if test "$ci_display_state" = "-"; or not set -q ci_display_state[1]
        set -e ci_display_state
    end
    if test "$ci_fetch_in_flight" = "-"
        set ci_fetch_in_flight false
    end
    set -l stars ""
    set -l forks ""
    set -l watchers ""
    set -l issues ""
    set -l prs ""
    if test -n "$line"
        set -l parts (string split " " "$line")
        set stars $parts[1]
        set forks $parts[2]
        set watchers $parts[3]
        set issues $parts[4]
        set prs $parts[5]
    end

    if test -z "$stars"
        set -l unavail (__tide_report_github_unavailable_display | string collect)
        _tide_print_item github (set_color $tide_report_github_unavailable_color)$unavail
        return
    end

    set -l ci_state "none"
    if test "$tide_report_github_show_ci" = true
        if set -q ci_display_state; and test -n "$ci_display_state"; and test "$ci_display_state" != "-"
            set ci_state "$ci_display_state"
        else if test -n "$ci_cache_file"
            set -l parsed_ci_state (__tide_report_github_read_ci_state "$ci_cache_file" | string collect)
            test -n "$parsed_ci_state"; and set ci_state "$parsed_ci_state"
            if test "$ci_fetch_in_flight" = true; and contains -- "$ci_state" pass fail none
                set ci_state pending
            end
        end
    end

    set -l out (__tide_report_render_github "$stars" "$forks" "$watchers" "$issues" "$prs" "$ci_state")
    if test -n "$out"
        _tide_print_item github "$out"
    end
end
