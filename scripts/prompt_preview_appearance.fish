## Maintainer-only Tide prompt styling for docs/assets/prompt-previews/.
##
## Edit these values to match your Tide theme or README reference screenshots.
## Applied by scripts/generate_prompt_previews.fish before calling
## _tide_report_install_show_preview. Not used on the live prompt path or Fisher installs.
##
## Fish color names (e.g. white, brblack) or hex without # (e.g. 444444, 5FAFAF) are accepted
## by set_color when mapped below.

# PNG letterbox outside prompt segments
set -g _preview_terminal_bg 000000

# Shared segment background for ellipsis + TideReport items
set -g _preview_segment_bg 444444

# Per-segment foreground colors
set -g _preview_time_color 5FAFAF
set -g _preview_github_color white
set -g _preview_weather_color 5FAFAF
set -g _preview_moon_color 5FAFAF
set -g _preview_tide_color 0087AF

# Powerline / patched-font glyphs (Private Use Area)
set -g _preview_powerline_prefix \uE0B2
set -g _preview_powerline_separator \uE0B3
set -g _preview_powerline_left_separator \uE0B0
set -g _preview_powerline_prefix_bg 000000
set -g _preview_separator_color brblack

# Dotted connector between left and right prompt sides in the combined "all" preview
set -g _preview_connection_icon ·
set -g _preview_connection_repeats 20

# Left github cap + middle connection in the combined "all" preview
set -g _preview_left_suffix \uE0B0
set -g _preview_connection_color brblack

# Typography passed to ansi_preview_to_png.py (--font / --font-size)
set -g _preview_font_family "FiraCode Nerd Font Mono, Noto Color Emoji"
set -g _preview_font_size 16

# Charm VHS capture (--vhs): single font family, viewport, terminal theme JSON
set -g _preview_vhs_font_family "FiraCode Nerd Font Mono"
set -g _preview_vhs_font_size 16
set -g _preview_vhs_width 1100
# Small viewport: VHS replays pre-captured ANSI via cat; post-crop trims letterbox.
set -g _preview_vhs_height 48
set -g _preview_vhs_postcrop_pad 12

function __prompt_preview_color_to_hex --argument-names color
    switch $color
        case white
            echo "#ffffff"
            return
        case brblack
            echo "#444444"
            return
        case brwhite
            echo "#e5e5e5"
            return
    end
    if string match -qr '^[0-9a-fA-F]{6}$' -- "$color"
        echo "#"(string lower -- "$color")
        return
    end
    echo "#d0d0d0"
end

function __prompt_preview_vhs_theme_json --description "xterm.js theme JSON for VHS Set Theme from _preview_* colors"
    set -l bg (__prompt_preview_color_to_hex $_preview_terminal_bg)
    set -l segment (__prompt_preview_color_to_hex $_preview_segment_bg)
    set -l cyan (__prompt_preview_color_to_hex $_preview_time_color)
    set -l blue (__prompt_preview_color_to_hex $_preview_tide_color)
    set -l white (__prompt_preview_color_to_hex $_preview_github_color)
    printf '{"background":"%s","foreground":"#d0d0d0","cursor":"#d0d0d0","black":"%s","brightBlack":"%s","cyan":"%s","brightCyan":"%s","blue":"%s","white":"%s"}' \
        $bg $bg $segment $cyan $cyan $blue $white
end

function __prompt_preview_apply_tide_appearance --description "Map _preview_* settings to tide_* for install_show_preview"
    set -g tide_time_color $_preview_time_color
    set -g tide_time_bg_color $_preview_segment_bg
    set -g tide_github_bg_color $_preview_segment_bg
    set -g tide_weather_bg_color $_preview_segment_bg
    set -g tide_moon_bg_color $_preview_segment_bg
    set -g tide_tide_bg_color $_preview_segment_bg

    set -g tide_github_color $_preview_github_color
    set -g tide_weather_color $_preview_weather_color
    set -g tide_moon_color $_preview_moon_color
    set -g tide_tide_color $_preview_tide_color

    set -g tide_left_prompt_separator_same_color $_preview_powerline_left_separator
    set -g tide_left_prompt_separator_diff_color $_preview_powerline_left_separator
    set -g tide_left_prompt_suffix $_preview_left_suffix

    set -g tide_right_prompt_prefix $_preview_powerline_prefix
    set -g tide_right_prompt_separator_same_color $_preview_powerline_separator
    set -g tide_right_prompt_separator_diff_color $_preview_powerline_separator

    set -g tide_color_separator_same_color $_preview_separator_color
    set -g tide_prompt_icon_connection (string repeat -n $_preview_connection_repeats -- "$_preview_connection_icon")
    set -g tide_prompt_color_frame_and_connection $_preview_connection_color
    set -g _tide_report_preview_omit_leading_ellipsis 1
end
