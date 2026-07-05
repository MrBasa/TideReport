#!/usr/bin/env python3
"""Trim letterbox padding from VHS screenshot PNGs, then restore a small margin.

Maintainer-only helper for scripts/generate_prompt_previews.fish --vhs.
When the capture includes a ``cat`` command line above the preview, crop to rows
that contain Tide segment background pixels before trim/pad.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

_DEFAULT_BG = "000000"
_DEFAULT_SEGMENT_BG = "444444"
_DEFAULT_PAD = 12


def _magick() -> str | None:
    return shutil.which("magick") or shutil.which("convert")


def _hex_to_rgb(hex_color: str) -> tuple[int, int, int]:
    h = hex_color.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def _row_has_segment_color(
    row_pixels: list[tuple[int, int, int]],
    segment_rgb: tuple[int, int, int],
    tolerance: int = 18,
) -> bool:
    sr, sg, sb = segment_rgb
    for r, g, b in row_pixels:
        if (
            abs(r - sr) <= tolerance
            and abs(g - sg) <= tolerance
            and abs(b - sb) <= tolerance
        ):
            return True
    return False


def _crop_to_segment_rows(png_path: Path, segment_bg: str) -> bool:
    try:
        from PIL import Image
    except ImportError:
        return False

    segment_rgb = _hex_to_rgb(segment_bg)
    img = Image.open(png_path).convert("RGB")
    width, height = img.size
    rows: list[int] = []
    for y in range(height):
        row_pixels = [img.getpixel((x, y)) for x in range(width)]
        if _row_has_segment_color(row_pixels, segment_rgb):
            rows.append(y)
    if not rows:
        return False
    top = max(0, min(rows) - 1)
    bottom = min(height, max(rows) + 2)
    cropped = img.crop((0, top, width, bottom))
    cropped.save(png_path)
    return True


def _trim_and_pad(png_path: Path, bg_hex: str, pad: int) -> bool:
    magick = _magick()
    if not magick:
        return False
    bg = bg_hex if bg_hex.startswith("#") else f"#{bg_hex}"
    trim_cmd = [magick, str(png_path), "-trim", "+repage", str(png_path)]
    pad_cmd = [
        magick,
        str(png_path),
        "-background",
        bg,
        "-gravity",
        "center",
        "-splice",
        f"{pad}x{pad}",
        str(png_path),
    ]
    for cmd in (trim_cmd, pad_cmd):
        result = subprocess.run(cmd, check=False)
        if result.returncode != 0:
            return False
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("png", type=Path, help="PNG path to trim and pad in place")
    parser.add_argument(
        "--bg",
        default=_DEFAULT_BG,
        help="Letterbox color without # (default: %(default)s)",
    )
    parser.add_argument(
        "--segment-bg",
        default=_DEFAULT_SEGMENT_BG,
        help="Tide segment background hex without # (default: %(default)s)",
    )
    parser.add_argument(
        "--pad",
        type=int,
        default=_DEFAULT_PAD,
        help="Pixels of margin to add on each side after trim (default: %(default)s)",
    )
    args = parser.parse_args()
    if not args.png.is_file():
        print(f"vhs_preview_postcrop.py: not a file: {args.png}", file=sys.stderr)
        return 1
    if args.pad < 0:
        print("vhs_preview_postcrop.py: --pad must be >= 0", file=sys.stderr)
        return 1
    if args.pad == 0:
        return 0
    _crop_to_segment_rows(args.png, args.segment_bg)
    if not _trim_and_pad(args.png, args.bg, args.pad):
        print(
            "vhs_preview_postcrop.py: ImageMagick magick/convert not found or failed; skipped",
            file=sys.stderr,
        )
        return 0
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
