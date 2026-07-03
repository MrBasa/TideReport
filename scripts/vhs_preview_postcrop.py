#!/usr/bin/env python3
"""Trim letterbox padding from VHS screenshot PNGs, then restore a small margin.

Maintainer-only helper for scripts/generate_prompt_previews.fish --vhs.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

_DEFAULT_BG = "000000"
_DEFAULT_PAD = 12


def _magick() -> str | None:
    return shutil.which("magick") or shutil.which("convert")


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
    if not _trim_and_pad(args.png, args.bg, args.pad):
        print(
            "vhs_preview_postcrop.py: ImageMagick magick/convert not found or failed; skipped",
            file=sys.stderr,
        )
        return 0
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
