#!/usr/bin/env python3
"""Rasterize a termtosvg still frame to a tight PNG (first row only, padded viewBox).

Maintainer-only helper for scripts/generate_prompt_previews.fish.
"""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

_ROW_HEIGHT = 24


def _prepare_still_svg(full_svg: str) -> str:
    svg = full_svg
    svg = re.sub(r"<rect[^>]*\by=\"17\"[^>]*/>\s*", "", svg)
    svg = re.sub(r"<use[^>]*\by=\"17\"[^>]*/>\s*", "", svg)
    width_match = re.search(r'viewBox="0 0 (\d+) \d+"', svg)
    if not width_match:
        raise ValueError("termtosvg_still_to_png: could not read terminal width")
    width = int(width_match.group(1))

    svg = re.sub(
        r'(<svg[^>]*id="terminal"[^>]*viewBox=")0 0 \d+ \d+(")',
        rf"\g<1>0 0 {width} {_ROW_HEIGHT}\2",
        svg,
        count=1,
    )
    svg = re.sub(
        r'(<svg id="screen"[^>]*viewBox=")0 0 \d+ \d+(")',
        rf"\g<1>0 0 {width} {_ROW_HEIGHT}\2",
        svg,
        count=1,
    )
    svg = re.sub(
        r'(<svg id="screen"[^>]*height=")\d+(")',
        rf"\g<1>{_ROW_HEIGHT}\2",
        svg,
        count=1,
    )
    svg = re.sub(r'height="\d+"', f'height="{_ROW_HEIGHT}"', svg, count=1)
    return svg


def _trim_horizontal(png_path: Path) -> None:
    magick = shutil.which("magick")
    if not magick:
        return
    subprocess.run(
        [
            magick,
            str(png_path),
            "-define",
            "trim:edges=east,west",
            "-fuzz",
            "2%",
            "-trim",
            "+repage",
            str(png_path),
        ],
        check=True,
        capture_output=True,
        text=True,
    )


def _rasterize(svg_path: Path, png_path: Path, bg_hex: str) -> None:
    bg = bg_hex if bg_hex.startswith("#") else f"#{bg_hex}"
    magick = shutil.which("magick")
    convert = shutil.which("convert")
    if magick:
        subprocess.run(
            [magick, "-background", bg, str(svg_path), "-flatten", str(png_path)],
            check=True,
            capture_output=True,
            text=True,
        )
        return
    if convert:
        subprocess.run(
            [convert, "-background", bg, str(svg_path), str(png_path)],
            check=True,
            capture_output=True,
            text=True,
        )
        return
    rsvg = shutil.which("rsvg-convert")
    if rsvg:
        subprocess.run(
            [rsvg, "-b", bg, "-o", str(png_path), str(svg_path)],
            check=True,
            capture_output=True,
            text=True,
        )
        return
    raise RuntimeError("termtosvg_still_to_png: need rsvg-convert or ImageMagick")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("svg", type=Path, help="termtosvg still frame SVG")
    parser.add_argument("output", type=Path, help="Output PNG path")
    parser.add_argument(
        "--bg",
        default="000000",
        help="Terminal background color (hex, optional #)",
    )
    parser.add_argument(
        "--no-trim",
        action="store_true",
        help="Skip horizontal trim of trailing canvas",
    )
    args = parser.parse_args()
    prepared = _prepare_still_svg(args.svg.read_text(encoding="utf-8"))
    with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False, encoding="utf-8") as tmp:
        tmp_path = Path(tmp.name)
        tmp.write(prepared)
    try:
        _rasterize(tmp_path, args.output, args.bg)
    except subprocess.CalledProcessError as exc:
        sys.stderr.write(exc.stderr or str(exc))
        return 1
    finally:
        tmp_path.unlink(missing_ok=True)
    if not args.no_trim:
        try:
            _trim_horizontal(args.output)
        except subprocess.CalledProcessError as exc:
            sys.stderr.write(exc.stderr or str(exc))
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
