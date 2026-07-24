"""Assemble reviewed image-generation outputs into exact 128px VFX sheets."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def assemble(
    source: Path,
    destination: Path,
    frame_count: int,
    content_size: int,
) -> None:
    image = Image.open(source).convert("RGBA")
    sheet = Image.new("RGBA", (frame_count * 128, 128), (0, 0, 0, 0))

    for index in range(frame_count):
        left = round(index * image.width / frame_count)
        right = round((index + 1) * image.width / frame_count)
        cell_width = right - left
        crop_size = min(cell_width, image.height)
        crop_left = left + (cell_width - crop_size) // 2
        crop_top = (image.height - crop_size) // 2
        frame = image.crop(
            (crop_left, crop_top, crop_left + crop_size, crop_top + crop_size)
        )
        frame = frame.resize((content_size, content_size), Image.Resampling.LANCZOS)
        inset = (128 - content_size) // 2
        sheet.alpha_composite(frame, (index * 128 + inset, inset))

    destination.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(destination, optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--frames", type=int, required=True)
    parser.add_argument("--content-size", type=int, default=112)
    args = parser.parse_args()
    assemble(args.input, args.out, args.frames, args.content_size)


if __name__ == "__main__":
    main()
