#!/usr/bin/env python3
"""Convert a single line of ANSI-colored terminal output to PNG (via SVG).

Maintainer-only helper for scripts/generate_prompt_previews.fish. Uses the
stdlib plus rsvg-convert (preferred) or ImageMagick convert for rasterization.
Color emoji (weather/moon) are composited with Pillow from Noto Color Emoji
after the SVG pass when that font is installed.
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from xml.sax.saxutils import escape

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:  # pragma: no cover - maintainer-only script
    Image = None  # type: ignore[misc, assignment]
    ImageDraw = None  # type: ignore[misc, assignment]
    ImageFont = None  # type: ignore[misc, assignment]

_BASIC = (
    "#000000",
    "#cd0000",
    "#00cd00",
    "#cdcd00",
    "#0000ee",
    "#cd00cd",
    "#00cdcd",
    "#e5e5e5",
    "#7f7f7f",
    "#ff0000",
    "#00ff00",
    "#ffff00",
    "#5c5cff",
    "#ff00ff",
    "#00ffff",
    "#ffffff",
)

_DEFAULT_FG = "#d0d0d0"
_DEFAULT_BG = "#000000"
_PADDING_X = 4
_PADDING_Y = 8
_FONT_SIZE = 16
_CELL_W = 9.6
_EMOJI_RENDER_SIZE = 109


@dataclass
class EmojiPlacement:
    text: str
    x: float


def _xterm256(n: int) -> str:
    if n < 16:
        return _BASIC[n]
    if n < 232:
        n -= 16
        r, g, b = n // 36, (n // 6) % 6, n % 6
        return "#{:02x}{:02x}{:02x}".format(
            55 + r * 40 if r else 0,
            55 + g * 40 if g else 0,
            55 + b * 40 if b else 0,
        )
    gray = 8 + (n - 232) * 10
    return "#{:02x}{:02x}{:02x}".format(gray, gray, gray)


def _rgb(r: int, g: int, b: int) -> str:
    return "#{:02x}{:02x}{:02x}".format(r, g, b)


def _char_width(ch: str) -> int:
    o = ord(ch)
    if o == 0xFE0F:
        return 0
    if o >= 0x1F300 or 0x2600 <= o <= 0x27BF or 0x2300 <= o <= 0x23FF:
        return 2
    if 0xE000 <= o <= 0xF8FF:
        return 1
    return 1


def _is_emoji_base(codepoint: int) -> bool:
    return (
        codepoint >= 0x1F300
        or 0x2600 <= codepoint <= 0x27BF
        or 0x2300 <= codepoint <= 0x23FF
    )


def _split_text_runs(text: str) -> list[tuple[str, bool]]:
    if not text:
        return []
    runs: list[tuple[str, bool]] = []
    i = 0
    n = len(text)
    while i < n:
        codepoint = ord(text[i])
        if codepoint in (0xFE0F, 0x200D):
            if runs and runs[-1][1]:
                runs[-1] = (runs[-1][0] + text[i], True)
            else:
                runs.append((text[i], True))
            i += 1
            continue
        is_emoji = _is_emoji_base(codepoint)
        j = i + 1
        if is_emoji:
            while j < n and ord(text[j]) in (0xFE0F, 0x200D):
                j += 1
        else:
            while j < n:
                next_cp = ord(text[j])
                if next_cp in (0xFE0F, 0x200D) or _is_emoji_base(next_cp):
                    break
                j += 1
        chunk = text[i:j]
        if runs and runs[-1][1] == is_emoji:
            runs[-1] = (runs[-1][0] + chunk, is_emoji)
        else:
            runs.append((chunk, is_emoji))
        i = j
    return runs


def _primary_font(font_family: str) -> str:
    return font_family.split(",")[0].strip()


def _resolve_emoji_font_path() -> str | None:
    env = os.environ.get("TIDE_REPORT_PREVIEW_EMOJI_FONT")
    if env and Path(env).is_file():
        return env
    fc_match = shutil.which("fc-match")
    if fc_match:
        try:
            result = subprocess.run(
                [fc_match, "-f", "%{file}", "Noto Color Emoji"],
                capture_output=True,
                text=True,
                check=True,
            )
            path = result.stdout.strip()
            if path and Path(path).is_file():
                return path
        except (subprocess.CalledProcessError, OSError):
            pass
    for candidate in (
        "/usr/share/fonts/noto/NotoColorEmoji.ttf",
        "/usr/share/fonts/google-noto-emoji/NotoColorEmoji.ttf",
    ):
        if Path(candidate).is_file():
            return candidate
    return None


def _render_emoji_run(text: str, target_height: int, font_path: str) -> Image.Image | None:
    if Image is None or ImageDraw is None or ImageFont is None:
        return None
    try:
        font = ImageFont.truetype(font_path, _EMOJI_RENDER_SIZE)
    except OSError:
        return None
    probe = Image.new("RGBA", (1, 1))
    drawer = ImageDraw.Draw(probe)
    bbox = drawer.textbbox((0, 0), text, font=font, embedded_color=True)
    width = max(1, bbox[2] - bbox[0])
    height = max(1, bbox[3] - bbox[1])
    img = Image.new("RGBA", (width + 2, height + 2), (0, 0, 0, 0))
    drawer = ImageDraw.Draw(img)
    drawer.text(
        (-bbox[0] + 1, -bbox[1] + 1),
        text,
        font=font,
        embedded_color=True,
    )
    if height != target_height:
        scale = target_height / height
        new_width = max(1, int(img.width * scale))
        img = img.resize((new_width, target_height), Image.Resampling.LANCZOS)
    return img


def _composite_emoji(
    png_path: Path,
    placements: list[EmojiPlacement],
    font_path: str,
    font_size: int,
) -> None:
    if not placements or Image is None:
        return
    target_height = int(font_size * 1.05)
    row_y = _PADDING_Y
    row_height = font_size * 1.25
    base = Image.open(png_path).convert("RGBA")
    for placement in placements:
        emoji = _render_emoji_run(placement.text, target_height, font_path)
        if emoji is None:
            continue
        x = int(placement.x)
        y = int(row_y + (row_height - emoji.height) / 2)
        base.alpha_composite(emoji, (x, y))
    base.save(png_path)


@dataclass
class Span:
    text: str
    fg: str
    bg: str


class AnsiParser:
    _re = re.compile(r"\x1b\[([0-9;]*)m")

    def __init__(self, default_fg: str, default_bg: str) -> None:
        self.default_fg = default_fg
        self.default_bg = default_bg
        self.fg = default_fg
        self.bg = default_bg

    def _apply(self, params: list[int]) -> None:
        if not params:
            params = [0]
        i = 0
        n = len(params)
        while i < n:
            code = params[i]
            if code == 0:
                self.fg = self.default_fg
                self.bg = self.default_bg
                i += 1
            elif code == 1:
                i += 1
            elif 30 <= code <= 37:
                self.fg = _BASIC[code - 30]
                i += 1
            elif code == 39:
                self.fg = self.default_fg
                i += 1
            elif 40 <= code <= 47:
                self.bg = _BASIC[code - 40]
                i += 1
            elif code == 49:
                self.bg = self.default_bg
                i += 1
            elif 90 <= code <= 97:
                self.fg = _BASIC[code - 90 + 8]
                i += 1
            elif 100 <= code <= 107:
                self.bg = _BASIC[code - 100 + 8]
                i += 1
            elif code in (38, 48):
                target = "fg" if code == 38 else "bg"
                i += 1
                if i >= n:
                    break
                mode = params[i]
                color = None
                if mode == 5 and i + 1 < n:
                    color = _xterm256(params[i + 1])
                    i += 2
                elif mode == 2 and i + 3 < n:
                    color = _rgb(params[i + 1], params[i + 2], params[i + 3])
                    i += 3
                else:
                    i += 1
                    continue
                if color is not None:
                    if target == "fg":
                        self.fg = color
                    else:
                        self.bg = color
                i += 1
            else:
                i += 1

    def parse(self, data: str) -> list[Span]:
        spans: list[Span] = []
        pos = 0
        for match in self._re.finditer(data):
            chunk = data[pos : match.start()]
            if chunk:
                spans.append(Span(chunk, self.fg, self.bg))
            raw = match.group(1)
            nums = [int(part) for part in raw.split(";") if part != ""] if raw else []
            self._apply(nums)
            pos = match.end()
        tail = data[pos:]
        if tail:
            spans.append(Span(tail, self.fg, self.bg))
        return spans


def _merge_spans(spans: list[Span]) -> list[Span]:
    if not spans:
        return []
    out = [spans[0]]
    for span in spans[1:]:
        prev = out[-1]
        if span.fg == prev.fg and span.bg == prev.bg:
            prev.text += span.text
        else:
            out.append(span)
    return out


def _svg_for_spans(
    spans: list[Span],
    font_family: str,
    font_size: int,
    canvas_bg: str,
) -> tuple[str, list[EmojiPlacement]]:
    spans = _merge_spans(spans)
    text_font = _primary_font(font_family)
    cell_w = font_size * 0.6
    row_h = font_size * 1.25
    cols = 0
    for span in spans:
        for ch in span.text:
            cols += _char_width(ch)
    width = int(_PADDING_X * 2 + cols * cell_w)
    height = int(_PADDING_Y * 2 + row_h)
    y = _PADDING_Y + font_size
    rects: list[str] = []
    texts: list[str] = []
    emoji_placements: list[EmojiPlacement] = []
    col = 0
    last_idx = len(spans) - 1
    for idx, span in enumerate(spans):
        span_start = col
        for ch in span.text:
            col += _char_width(ch)
        if span.bg.lower() != canvas_bg.lower():
            rx = _PADDING_X + span_start * cell_w
            rw = (col - span_start) * cell_w
            if idx < last_idx:
                rw += 0.8
            rects.append(
                f'<rect x="{rx:.1f}" y="{_PADDING_Y}" width="{rw:.1f}" '
                f'height="{row_h:.1f}" fill="{span.bg}"/>'
            )
        run_col = span_start
        for run_text, is_emoji in _split_text_runs(span.text):
            run_start = run_col
            for ch in run_text:
                run_col += _char_width(ch)
            if is_emoji:
                stripped = run_text.strip()
                if stripped:
                    emoji_placements.append(
                        EmojiPlacement(
                            text=run_text,
                            x=_PADDING_X + run_start * cell_w,
                        )
                    )
                continue
            if not run_text:
                continue
            tx = _PADDING_X + run_start * cell_w
            texts.append(
                f'<text x="{tx:.1f}" y="{y:.1f}" fill="{span.fg}" '
                f'font-family="{escape(text_font)}">{escape(run_text)}</text>'
            )
    body = "\n  ".join(rects + texts)
    svg = (
        f'<?xml version="1.0" encoding="UTF-8"?>\n'
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}">\n'
        f'  <rect width="100%" height="100%" fill="{canvas_bg}"/>\n'
        f'  <g font-family="{escape(text_font)}" font-size="{font_size}" '
        f'xml:space="preserve">\n  {body}\n  </g>\n</svg>\n'
    )
    return svg, emoji_placements


def _rasterize(svg_path: Path, png_path: Path) -> None:
    # Prefer ImageMagick for best emoji/font rendering.
    magick = shutil.which("magick")
    if magick:
        subprocess.run(
            [magick, "-background", "none", str(svg_path), "-flatten", str(png_path)],
            check=True,
            capture_output=True,
            text=True,
        )
        return
    convert = shutil.which("convert")
    if convert:
        subprocess.run(
            [convert, str(svg_path), str(png_path)],
            check=True,
            capture_output=True,
            text=True,
        )
        return
    rsvg = shutil.which("rsvg-convert")
    if rsvg:
        subprocess.run(
            [rsvg, "-o", str(png_path), str(svg_path)],
            check=True,
            capture_output=True,
            text=True,
        )
        return
    raise RuntimeError(
        "ansi_preview_to_png.py: need rsvg-convert (librsvg) or ImageMagick on PATH"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="File containing one ANSI line")
    parser.add_argument("output", type=Path, help="Output PNG path")
    parser.add_argument(
        "--font",
        default="FiraCode Nerd Font Mono",
        help="Font family for SVG text (must be installed locally)",
    )
    parser.add_argument("--font-size", type=int, default=_FONT_SIZE)
    parser.add_argument(
        "--bg",
        default=_DEFAULT_BG,
        help="Terminal canvas background color (hex, with or without #)",
    )
    parser.add_argument(
        "--keep-svg",
        action="store_true",
        help="Keep intermediate SVG next to the PNG",
    )
    args = parser.parse_args()
    canvas_bg = args.bg if args.bg.startswith("#") else f"#{args.bg}"
    raw = args.input.read_text(encoding="utf-8", errors="replace").rstrip("\n")
    spans = AnsiParser(_DEFAULT_FG, canvas_bg).parse(raw)
    svg, emoji_placements = _svg_for_spans(spans, args.font, args.font_size, canvas_bg)
    svg_path = args.output.with_suffix(".svg")
    svg_path.write_text(svg, encoding="utf-8")
    try:
        _rasterize(svg_path, args.output)
    except subprocess.CalledProcessError as exc:
        sys.stderr.write(exc.stderr or str(exc))
        return 1
    if emoji_placements:
        emoji_font = _resolve_emoji_font_path()
        if emoji_font:
            _composite_emoji(args.output, emoji_placements, emoji_font, args.font_size)
        else:
            print(
                "ansi_preview_to_png.py: warning — emoji in preview but "
                "Noto Color Emoji not found; install noto-fonts-emoji",
                file=sys.stderr,
            )
    if not args.keep_svg:
        svg_path.unlink(missing_ok=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
