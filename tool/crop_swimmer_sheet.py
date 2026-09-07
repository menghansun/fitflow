from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


def _runs(mask: np.ndarray) -> list[tuple[int, int]]:
    edges = np.flatnonzero(np.diff(np.r_[False, mask, False]))
    return [(int(start), int(end)) for start, end in edges.reshape(-1, 2)]


def _detect_frame_bounds(
    image: Image.Image,
    *,
    columns: int,
    rows: int,
) -> list[tuple[int, int, int, int]]:
    alpha = np.asarray(image.getchannel("A")) > 0
    row_bounds = _runs(alpha.any(axis=1))
    if len(row_bounds) != rows:
        raise ValueError(f"Expected {rows} sprite rows, found {len(row_bounds)}")

    bounds: list[tuple[int, int, int, int]] = []
    for top, bottom in row_bounds:
        column_bounds = _runs(alpha[top:bottom].any(axis=0))
        if len(column_bounds) != columns:
            raise ValueError(
                f"Expected {columns} sprites in row {len(bounds) // columns + 1}, "
                f"found {len(column_bounds)}"
            )
        bounds.extend(
            (left, top, right, bottom) for left, right in column_bounds
        )
    return bounds


def _build_preview(frames: list[Image.Image], *, duration_ms: int) -> list[Image.Image]:
    preview_frames: list[Image.Image] = []
    for frame in frames:
        canvas = Image.new("RGBA", (760, 280), "#DDF5FB")
        draw = ImageDraw.Draw(canvas)
        draw.line((0, 24, 760, 24), fill="#F6B94A", width=7)
        draw.line((0, 256, 760, 256), fill="#F6B94A", width=7)
        draw.line((0, 140, 760, 140), fill="#A6DDEB", width=2)

        max_width, max_height = 610, 205
        scale = min(max_width / frame.width, max_height / frame.height)
        size = (round(frame.width * scale), round(frame.height * scale))
        swimmer = frame.resize(size, Image.Resampling.LANCZOS)
        position = ((canvas.width - swimmer.width) // 2, (canvas.height - swimmer.height) // 2)
        canvas.alpha_composite(swimmer, position)
        preview_frames.append(canvas)
    return preview_frames


def crop_sheet(
    source: Path,
    output: Path,
    *,
    columns: int,
    rows: int,
    padding: int,
    duration_ms: int,
) -> None:
    image = Image.open(source).convert("RGBA")
    bounds = _detect_frame_bounds(image, columns=columns, rows=rows)

    frame_width = max(right - left for left, _, right, _ in bounds) + padding * 2
    frame_height = max(bottom - top for _, top, _, bottom in bounds) + padding * 2

    frames_dir = output / "frames"
    frames_dir.mkdir(parents=True, exist_ok=True)

    frames: list[Image.Image] = []
    for index, (left, top, right, bottom) in enumerate(bounds):
        sprite = image.crop((left, top, right, bottom))
        frame = Image.new("RGBA", (frame_width, frame_height), (0, 0, 0, 0))
        position = (
            (frame_width - sprite.width) // 2,
            (frame_height - sprite.height) // 2,
        )
        frame.alpha_composite(sprite, position)
        frame.save(frames_dir / f"frame_{index:02d}.png", optimize=True)
        frames.append(frame)

    sheet = Image.new(
        "RGBA",
        (frame_width * columns, frame_height * rows),
        (0, 0, 0, 0),
    )
    for index, frame in enumerate(frames):
        sheet.alpha_composite(
            frame,
            ((index % columns) * frame_width, (index // columns) * frame_height),
        )
    sheet.save(output / "sprite_sheet.png", optimize=True)

    preview_frames = _build_preview(frames, duration_ms=duration_ms)
    preview_frames[0].save(
        output / "preview.gif",
        save_all=True,
        append_images=preview_frames[1:],
        duration=duration_ms,
        loop=0,
        disposal=2,
        optimize=False,
    )

    print(f"frames={len(frames)}")
    print(f"frame_size={frame_width}x{frame_height}")
    print(f"cycle_ms={len(frames) * duration_ms}")
    print(f"output={output}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--columns", type=int, required=True)
    parser.add_argument("--rows", type=int, required=True)
    parser.add_argument("--padding", type=int, default=16)
    parser.add_argument("--duration-ms", type=int, default=100)
    args = parser.parse_args()

    crop_sheet(
        args.source,
        args.output,
        columns=args.columns,
        rows=args.rows,
        padding=args.padding,
        duration_ms=args.duration_ms,
    )


if __name__ == "__main__":
    main()
