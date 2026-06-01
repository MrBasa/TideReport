#!/usr/bin/env python3
"""Convert a single line of ANSI-colored terminal output to PNG (via SVG).

Maintainer-only helper for scripts/generate_prompt_previews.fish. Uses the
stdlib plus rsvg-convert (preferred) or ImageMagick convert for rasterization.
Falls back when termtosvg is unavailable.
"""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from xml.sax.saxutils import escape

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
) -> str:
    spans = _merge_spans(spans)
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
    col = 0
    last_idx = len(spans) - 1
    for idx, span in enumerate(spans):
        start_col = col
        for ch in span.text:
            col += _char_width(ch)
        if span.bg.lower() != canvas_bg.lower():
            rx = _PADDING_X + start_col * cell_w
            rw = (col - start_col) * cell_w
            if idx < last_idx:
                rw += 0.8
            rects.append(
                f'<rect x="{rx:.1f}" y="{_PADDING_Y}" width="{rw:.1f}" '
                f'height="{row_h:.1f}" fill="{span.bg}"/>'
            )
        tx = _PADDING_X + start_col * cell_w
        texts.append(
            f'<text x="{tx:.1f}" y="{y:.1f}" fill="{span.fg}">{escape(span.text)}</text>'
        )
    body = "\n  ".join(rects + texts)
    return (
        f'<?xml version="1.0" encoding="UTF-8"?>\n'
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}">\n'
        f'  <rect width="100%" height="100%" fill="{canvas_bg}"/>\n'
        f'  <g font-family="{escape(font_family)}" font-size="{font_size}" '
        f'xml:space="preserve">\n  {body}\n  </g>\n</svg>\n'
    )


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
    svg = _svg_for_spans(spans, args.font, args.font_size, canvas_bg)
    svg_path = args.output.with_suffix(".svg")
    svg_path.write_text(svg, encoding="utf-8")
    try:
        _rasterize(svg_path, args.output)
    except subprocess.CalledProcessError as exc:
        sys.stderr.write(exc.stderr or str(exc))
        return 1
    if not args.keep_svg:
        svg_path.unlink(missing_ok=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
