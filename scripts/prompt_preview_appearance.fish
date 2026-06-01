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
