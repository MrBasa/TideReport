#!/usr/bin/env fish
## Maintainer-only: regenerate README prompt preview PNGs from the install wizard helper.
##
## Fisher installs conf.d/ and functions/ only — this script is NOT part of the plugin.
## Do not wire it into install paths, wizard flows, or tide-report CLI subcommands.
##
## Tide segment styling: edit scripts/prompt_preview_appearance.fish
##
## Requirements (maintainer machine):
##   - Fish 3.x+, Python 3, a Nerd Font (see prompt_preview_appearance.fish)
##   - Default: ImageMagick `magick`/`convert` or rsvg-convert for ANSI→PNG
##   - Optional --termtosvg: termtosvg in scripts/.preview-venv (auto-created)
##   - Optional --vhs: vhs, ttyd, ffmpeg, Noto Color Emoji (see README)
##   - TERM=xterm-256color (set automatically; required for set_color output)
##
## Usage (from repo root):
##   fish scripts/generate_prompt_previews.fish
##   fish scripts/generate_prompt_previews.fish --open
##   fish scripts/generate_prompt_previews.fish --termtosvg   # optional alt renderer
##   fish scripts/generate_prompt_previews.fish --vhs         # color emoji / Powerline
##
## Output: docs/assets/prompt-previews/*.png

set -l repo_root (command realpath (status dirname)/..)
set -l out_dir "$repo_root/docs/assets/prompt-previews"
set -l appearance "$repo_root/scripts/prompt_preview_appearance.fish"
set -l converter "$repo_root/scripts/ansi_preview_to_png.py"
set -l postproc "$repo_root/scripts/termtosvg_still_to_png.py"
set -l vhs_template "$repo_root/scripts/prompt_preview_vhs.tape.template"
set -l vhs_postcrop "$repo_root/scripts/vhs_preview_postcrop.py"
set -l venv "$repo_root/scripts/.preview-venv"
set -l termtosvg "$venv/bin/termtosvg"
set -l open_when_done 0
set -l use_termtosvg 0
set -l use_vhs 0

argparse o/open t/termtosvg v/vhs -- $argv
or exit $status
if set -q _flag_open
    set open_when_done 1
end
if set -q _flag_termtosvg
    set use_termtosvg 1
end
if set -q _flag_vhs
    set use_vhs 1
    set use_termtosvg 0
end

if not test -f "$appearance"
    echo "generate_prompt_previews.fish: missing $appearance" >&2
    exit 1
end

if test $use_vhs -eq 1
    if not test -f "$vhs_template"
        echo "generate_prompt_previews.fish: missing $vhs_template" >&2
        exit 1
    end
    for cmd in vhs ttyd ffmpeg
        if not command -sq $cmd
            echo "generate_prompt_previews.fish: --vhs requires $cmd on PATH" >&2
            exit 1
        end
    end
else
    if not test -f "$converter"
        echo "generate_prompt_previews.fish: missing $converter" >&2
        exit 1
    end
    if not command -sq python3
        echo "generate_prompt_previews.fish: python3 is required" >&2
        exit 1
    end
end

if test $use_termtosvg -eq 1
    if not test -f "$postproc"
        echo "generate_prompt_previews.fish: missing $postproc" >&2
        exit 1
    end
    if not test -x "$termtosvg"
        echo "generate_prompt_previews.fish: creating $venv and installing termtosvg…" >&2
        python3 -m venv "$venv"
        or begin
            echo "generate_prompt_previews.fish: failed to create Python venv" >&2
            exit 1
        end
        "$venv/bin/pip" install -q termtosvg
        or begin
            echo "generate_prompt_previews.fish: pip install termtosvg failed" >&2
            exit 1
        end
    end
end

if test $use_vhs -eq 0
    if not command -sq magick; and not command -sq convert; and not command -sq rsvg-convert
        echo "generate_prompt_previews.fish: install ImageMagick (magick) or rsvg-convert" >&2
        exit 1
    end
end

source "$appearance"
if not fc-list : family | string match -qi "*Nerd*"
    echo "generate_prompt_previews.fish: warning — no Nerd Font detected via fc-list; icons may render incorrectly" >&2
end
if test $use_vhs -eq 1
    if not fc-list : family | string match -qi "*Noto*Emoji*"
        echo "generate_prompt_previews.fish: warning — Noto Color Emoji not found via fc-list; weather/moon emoji may be missing" >&2
    end
end

mkdir -p "$out_dir"

set -l tmp (command mktemp -d)
set -lx HOME "$tmp/home"
set -lx XDG_CONFIG_HOME "$tmp/.config"
set -lx XDG_DATA_HOME "$tmp/.local/share"
set -lx XDG_STATE_HOME "$tmp/.local/state"
set -lx TERM xterm-256color
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"

set -l preview_runner "$tmp/run_preview.fish"
begin
    echo "set -g REPO_ROOT '$repo_root'"
    echo "source \"\$REPO_ROOT/test/helpers/setup.fish\""
    echo "source \"\$REPO_ROOT/functions/_tide_report_prompt_helpers.fish\""
    echo "source \"\$REPO_ROOT/functions/_tide_report_github_parse.fish\""
    echo "source \"\$REPO_ROOT/functions/_tide_item_weather.fish\""
    echo "source \"\$REPO_ROOT/functions/_tide_item_moon.fish\""
    echo "source \"\$REPO_ROOT/functions/_tide_report_tide_helpers.fish\""
    echo "source \"\$REPO_ROOT/scripts/prompt_preview_appearance.fish\""
    echo "__prompt_preview_apply_tide_appearance"
    echo "set -l which \$argv[1]"
    echo "set -l weather_format \$argv[2]"
    echo "set -l units \$argv[3]"
    echo "set -g tide_report_units \$units"
    echo "_tide_report_install_show_preview \$which \$weather_format normal"
end >"$preview_runner"

set -l variants \
    all-medium-metric\|all\|medium\|m \
    all-medium-us\|all\|medium\|u \
    github\|github\|medium\|m \
    weather-concise-metric\|weather\|concise\|m \
    weather-medium-metric\|weather\|medium\|m \
    weather-detailed-metric\|weather\|detailed\|m \
    weather-concise-us\|weather\|concise\|u \
    weather-medium-us\|weather\|medium\|u \
    weather-detailed-us\|weather\|detailed\|u \
    moon\|moon\|medium\|m \
    tide\|tide\|medium\|m

function __preview_visible_columns --argument-names line
    set -l plain (string replace -ra '\e\[[0-9;]*m' '' -- "$line")
    set -l cols 0
    for ch in (string split "" -- "$plain")
        test -z "$ch"; and continue
        set -l w (__preview_char_width "$ch")
        set cols (math $cols + $w)
    end
    math $cols + 2
end

function __preview_char_width --argument-names ch
    set -l len (string length -- "$ch")
    if test $len -gt 1
        echo 2
        return
    end
    echo 1
end

function __preview_ansi_to_png --argument-names converter ansi_file png_file
    python3 "$converter" "$ansi_file" "$png_file" \
        --font "$_preview_font_family" \
        --font-size "$_preview_font_size" \
        --bg "$_preview_terminal_bg"
end

function __preview_termtosvg_to_png --argument-names work_dir runner slug which wfmt units png_file termtosvg_bin postproc
    set -l cols 80
    set -l sample (fish --no-config "$runner" $which $wfmt $units 2>/dev/null)
    if test -n "$sample"
        set cols (__preview_visible_columns "$sample")
        if test $cols -lt 24
            set cols 24
        end
        if test $cols -gt 120
            set cols 120
        end
    end

    set -l frame_dir "$work_dir/termtosvg-$slug"
    mkdir -p "$frame_dir"
    # Two rows: row 0 = preview output, row 1 = blank cursor line (stripped in post-process).
    env TERM=xterm-256color "$termtosvg_bin" "$frame_dir" -g "$cols"x2 -s \
        -c "fish --no-config $runner $which $wfmt $units" >/dev/null 2>/dev/null
    if test $status -ne 0; or not test -f "$frame_dir/termtosvg_00000.svg"
        return 1
    end

    if not test -f "$postproc"
        return 1
    end
    python3 "$postproc" "$frame_dir/termtosvg_00000.svg" "$png_file" --bg "$_preview_terminal_bg"
    return $status
end

function __preview_substitute_vhs_tape --argument-names template dest ansi_file which wfmt units png_capture throwaway_rel
    set -l theme (__prompt_preview_vhs_theme_json)
    command rm -f "$dest"
    while read line
        set line (string replace -a '{{THROWAWAY_GIF}}' "$throwaway_rel" -- $line)
        set line (string replace -a '{{ANSI_FILE}}' "$ansi_file" -- $line)
        set line (string replace -a '{{WHICH}}' "$which" -- $line)
        set line (string replace -a '{{WFMT}}' "$wfmt" -- $line)
        set line (string replace -a '{{UNITS}}' "$units" -- $line)
        set line (string replace -a '{{PNG_CAPTURE}}' "$png_capture" -- $line)
        set line (string replace -a '{{HOME}}' "$HOME" -- $line)
        set line (string replace -a '{{XDG_CONFIG_HOME}}' "$XDG_CONFIG_HOME" -- $line)
        set line (string replace -a '{{XDG_DATA_HOME}}' "$XDG_DATA_HOME" -- $line)
        set line (string replace -a '{{XDG_STATE_HOME}}' "$XDG_STATE_HOME" -- $line)
        set line (string replace -a '{{FONT_FAMILY}}' "$_preview_vhs_font_family" -- $line)
        set line (string replace -a '{{FONT_SIZE}}' "$_preview_vhs_font_size" -- $line)
        set line (string replace -a '{{WIDTH}}' "$_preview_vhs_width" -- $line)
        set line (string replace -a '{{HEIGHT}}' "$_preview_vhs_height" -- $line)
        set line (string replace -a '{{THEME_JSON}}' "$theme" -- $line)
        echo "$line" >>"$dest"
    end <$template
end

function __preview_vhs_to_png --argument-names repo_root work_dir template runner slug which wfmt units png_file postcrop_script
    # VHS 0.11 parses Screenshot paths poorly when they contain slashes; capture flat, then mv.
    set -l png_capture "preview-capture-$slug.png"
    set -l throwaway_rel "throwaway.gif"
    set -l tape_file "$work_dir/vhs-$slug.tape"
    set -l capture_file "$repo_root/$png_capture"
    set -l ansi_file "$work_dir/$slug.ansi"
    mkdir -p "$work_dir"
    fish --no-config "$runner" $which $wfmt $units >"$ansi_file" 2>/dev/null
    if test $status -ne 0; or not test -s "$ansi_file"
        echo "generate_prompt_previews.fish: VHS ANSI capture failed for $slug" >&2
        return 1
    end
    __preview_substitute_vhs_tape "$template" "$tape_file" "$ansi_file" "$which" "$wfmt" "$units" "$png_capture" "$throwaway_rel"

    pushd "$repo_root" >/dev/null
    set -l vhs_err (vhs "$tape_file" 2>&1)
    set -l st $status
    command rm -f "$repo_root/$throwaway_rel" 2>/dev/null
    popd >/dev/null

    if test $st -ne 0
        for line in $vhs_err
            echo $line >&2
        end
        return 1
    end
    if not test -f "$capture_file"
        echo "generate_prompt_previews.fish: VHS did not write $capture_file" >&2
        return 1
    end
    command mv -f "$capture_file" "$png_file"
    if test -f "$postcrop_script"
        python3 "$postcrop_script" "$png_file" --bg "$_preview_terminal_bg" --segment-bg "$_preview_segment_bg" --pad "$_preview_vhs_postcrop_pad" 2>/dev/null
    end
    return 0
end

set -l written_paths

for spec in $variants
    set -l parts (string split "|" -- $spec)
    set -l slug $parts[1]
    set -l which $parts[2]
    set -l wfmt $parts[3]
    set -l units $parts[4]
    set -l png_file "$out_dir/$slug.png"

    set -l ok 0
    if test $use_vhs -eq 1
        __preview_vhs_to_png "$repo_root" "$tmp" "$vhs_template" "$preview_runner" "$slug" "$which" "$wfmt" "$units" "$png_file" "$vhs_postcrop"
        or begin
            echo "generate_prompt_previews.fish: VHS capture failed for $slug" >&2
            command rm -rf "$tmp"
            exit 1
        end
        set ok 1
    else
        set -l ansi_file "$tmp/$slug.ansi"
        fish --no-config "$preview_runner" $which $wfmt $units >"$ansi_file" 2>/dev/null
        if test $status -ne 0; or not test -s "$ansi_file"
            echo "generate_prompt_previews.fish: preview capture failed for $slug" >&2
            command rm -rf "$tmp"
            exit 1
        end

        if test $use_termtosvg -eq 1
            __preview_termtosvg_to_png "$tmp" "$preview_runner" "$slug" $which $wfmt $units "$png_file" "$termtosvg" "$postproc"
            and set ok 1
        end
        if test $ok -eq 0
            __preview_ansi_to_png "$converter" "$ansi_file" "$png_file"
            or begin
                echo "generate_prompt_previews.fish: PNG conversion failed for $slug" >&2
                command rm -rf "$tmp"
                exit 1
            end
        end
    end
    set -a written_paths $png_file
end

command rm -rf "$tmp"

set -l backend "ANSI→PNG"
if test $use_vhs -eq 1
    set backend "VHS"
else if test $use_termtosvg -eq 1
    set backend "termtosvg"
end

echo "Wrote "(count $written_paths)" preview PNG(s) via $backend to $out_dir:"
for path in $written_paths
    echo "  $path"
end
echo "Tide styling: $appearance"

if test $open_when_done -eq 1
    if command -sq xdg-open
        xdg-open "$out_dir" >/dev/null 2>&1 &
    else if command -sq open
        open "$out_dir"
    end
end

exit 0
