"""Repack unchanged sprite cells into a <=4096 atlas. Never resize the artwork."""
import argparse
from pathlib import Path
from PIL import Image


def repack_pages(source: Path, destination: Path, width: int, height: int, frames: int,
                 columns: int, limit: int = 4096) -> tuple[int, list[tuple[Path, int]]]:
    if min(width, height, frames, columns, limit) <= 0:
        raise ValueError("Atlas dimensions and counts must be positive")
    new_columns = min(columns, limit // width)
    capacity = new_columns * (limit // height)
    if not capacity:
        raise ValueError("A single source frame exceeds the texture budget")
    pages = []
    with Image.open(source) as image:
        if image.mode != "RGBA" or image.size != (width * columns, height * ((frames + columns - 1) // columns)):
            raise ValueError("Source grid or RGBA mode differs from its declared contract")
        for start in range(0, frames, capacity):
            count = min(capacity, frames - start)
            output = destination if capacity >= frames else destination.with_stem(destination.stem + f"-page-{len(pages)+1:02d}")
            packed = Image.new("RGBA", (width * new_columns, height * ((count + new_columns - 1) // new_columns)))
            for index in range(count):
                frame = start + index;x,y=frame % columns * width,frame // columns * height
                packed.paste(image.crop((x,y,x+width,y+height)),(index % new_columns * width,index // new_columns * height))
            output.parent.mkdir(parents=True,exist_ok=True);packed.save(output,optimize=True)
            pages.append((output,count))
    return new_columns,pages


def repack(source: Path, destination: Path, width: int, height: int, frames: int, columns: int,
           limit: int = 4096) -> int:
    if min(width, height, frames, columns, limit) <= 0:
        raise ValueError("Atlas dimensions and counts must be positive")
    new_columns = min(columns, limit // width)
    if not new_columns or ((frames + new_columns - 1) // new_columns) * height > limit:
        raise ValueError("Frames cannot fit in one atlas without resizing or splitting")
    with Image.open(source) as image:
        if image.mode != "RGBA" or image.size != (width * columns, height * ((frames + columns - 1) // columns)):
            raise ValueError("Source grid or RGBA mode differs from its declared contract")
        packed = Image.new("RGBA", (width * new_columns, height * ((frames + new_columns - 1) // new_columns)))
        for frame in range(frames):
            x, y = frame % columns * width, frame // columns * height
            cell = image.crop((x, y, x + width, y + height))
            packed.paste(cell, (frame % new_columns * width, frame // new_columns * height))
        destination.parent.mkdir(parents=True, exist_ok=True)
        packed.save(destination, optimize=True)
    return new_columns


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--frame-width", required=True, type=int)
    parser.add_argument("--frame-height", required=True, type=int)
    parser.add_argument("--frames", required=True, type=int)
    parser.add_argument("--columns", required=True, type=int)
    args = parser.parse_args()
    if args.output.resolve().is_relative_to(Path(__file__).resolve().parents[1] / "assets"):
        parser.error("Normalize into staging; publish through a new asset release")
    columns,pages=repack_pages(args.source,args.output,args.frame_width,args.frame_height,args.frames,args.columns)
    print("columns:",columns,"pages:",[(str(path),count) for path,count in pages])
