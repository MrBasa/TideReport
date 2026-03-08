#!/usr/bin/env fish
## Diagnose Tide/TideReport prompt variables (e.g. missing prompt character / cursor on same line).
## Run in the affected Fish shell: fish scripts/diagnose_tide_prompt.fish
## Or from repo root: fish scripts/diagnose_tide_prompt.fish

echo (set_color brwhite)"=== Tide / TideReport variables ===" (set_color normal)
echo ""

echo "tide_left_prompt_items:"
if set -q tide_left_prompt_items
    echo "  → " (string join " " $tide_left_prompt_items)
else
    echo "  (unset)"
end
echo ""

echo "tide_right_prompt_items:"
if set -q tide_right_prompt_items
    echo "  → " (string join " " $tide_right_prompt_items)
else
    echo "  (unset)"
end
echo ""

set -l has_newline 0
set -l has_character 0
if set -q tide_left_prompt_items
for i in $tide_left_prompt_items
    test "$i" = "newline" && set has_newline 1
    test "$i" = "character" && set has_character 1
end
end

if test $has_newline -eq 0; or test $has_character -eq 0
    echo (set_color bryellow)"⚠ Left prompt is missing items Tide needs for a two-line prompt:"(set_color normal)
    test $has_newline -eq 0 && echo "  - 'newline' (adds the line break before the prompt character)"
    test $has_character -eq 0 && echo "  - 'character' (shows the ❯ prompt character)"
    echo ""
    echo (set_color brwhite)"Fix: add newline and character to the left prompt, then reload Tide."(set_color normal)
    set -l fixed
    if set -q tide_left_prompt_items; and test (count $tide_left_prompt_items) -gt 0
        set fixed $tide_left_prompt_items
    else
        set fixed pwd git
    end
    test $has_newline -eq 0 && set -a fixed newline
    test $has_character -eq 0 && set -a fixed character
    echo (set_color cyan)"  set -U tide_left_prompt_items " (string join " " $fixed)(set_color normal)
    echo ""
    echo (set_color cyan)"  tide reload"(set_color normal)
    echo ""
    echo "Alternatively, run " (set_color cyan)"tide configure" (set_color normal)" to reset the prompt."
    exit 1
end

echo (set_color green)"Left prompt contains 'newline' and 'character'." (set_color normal)
echo "If the prompt is still broken, check for global overrides:"
echo "  set -q -g tide_left_prompt_items && echo 'WARNING: global tide_left_prompt_items is set (overrides universal)'"
exit 0
