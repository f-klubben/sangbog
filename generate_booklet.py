#!/usr/bin/env python3
"""
Booklet generator: takes an A4 portrait PDF and produces an A4 landscape PDF
with two pages per sheet arranged for booklet (saddle-stitch) printing.

Booklet ordering for N sheets (4 pages per sheet front+back):
    Sheet 1 front:  [last, first]
    Sheet 1 back:   [second, second-to-last]
    Sheet 2 front:  [third-to-last, third]
    ...

Usage:
    python booklet.py input.pdf output.pdf
    python booklet.py input.pdf output.pdf --no-pad   # don't pad to multiple of 4
"""

import sys
import argparse
import math
from pathlib import Path
from pypdf import PdfReader, PdfWriter, PageObject, Transformation
from pypdf.papersizes import PaperSize


A4_W = PaperSize.A4.width    # 595 pt
A4_H = PaperSize.A4.height   # 842 pt

# A4 landscape: swap width and height
SHEET_W = A4_H  # 842 pt
SHEET_H = A4_W  # 595 pt


def build_booklet_order(n_pages: int) -> list[int | None]:
    """
    Return a flat list of page indices (0-based) in booklet order.
    None means a blank page.

    For a booklet printed double-sided and folded:
      The list is grouped in pairs: each pair is one side of one sheet.
      Pairs alternate: [right-of-front, left-of-front, left-of-back, right-of-back, ...]

    For 8 pages:
      Sheet 1 front: pages 8, 1   (right=1, left=8)
      Sheet 1 back:  pages 2, 7   (left=2, right=7)
      Sheet 2 front: pages 6, 3   (right=3, left=6)
      Sheet 2 back:  pages 4, 5   (left=4, right=5)
    """
    # Pad to multiple of 4
    total = math.ceil(n_pages / 4) * 4
    # Page list padded with None
    pages = list(range(n_pages)) + [None] * (total - n_pages)

    order = []
    lo, hi = 0, total - 1
    while lo < hi:
        # Front of sheet: right=lo+1 (0-based: lo), left=hi
        order.append((pages[hi], pages[lo]))   # front: left=hi, right=lo
        lo += 1
        hi -= 1
        order.append((pages[lo], pages[hi]))   # back:  left=lo, right=hi
        lo += 1
        hi -= 1

    return order, total


def place_page_on_sheet(writer: PdfWriter, left_idx, right_idx, reader: PdfReader, rotate: bool = False):
    """
    Create one A4 landscape sheet with left_idx page on the left half
    and right_idx page on the right half. None means blank.
    If rotate is True, both slots are rotated 180° (for back sides in duplex printing).
    """
    sheet = PageObject.create_blank_page(width=SHEET_W, height=SHEET_H)

    for page_idx, x_offset in [(left_idx, 0), (right_idx, SHEET_W / 2)]:
        if page_idx is None:
            continue

        src = reader.pages[page_idx]

        src_box = src.mediabox
        src_w = float(src_box.width)
        src_h = float(src_box.height)

        slot_w = SHEET_W / 2
        slot_h = SHEET_H

        scale = min(slot_w / src_w, slot_h / src_h)
        scaled_w = src_w * scale
        scaled_h = src_h * scale

        if rotate:
            # Rotate 180° within the slot: origin shifts to top-right of slot
            tx = x_offset + (slot_w + scaled_w) / 2
            ty = (slot_h + scaled_h) / 2
            transform = (
                Transformation()
                .scale(scale, scale)
                .rotate(180)
                .translate(tx, ty)
            )
        else:
            tx = x_offset + (slot_w - scaled_w) / 2
            ty = (slot_h - scaled_h) / 2
            transform = Transformation().scale(scale, scale).translate(tx, ty)

        sheet.merge_transformed_page(src, transform, over=True, expand=False)

    writer.add_page(sheet)


def generate_booklet(input_path: str, output_path: str, pad: bool = True, rotate_backs: bool = True):
    reader = PdfReader(input_path)
    n_pages = len(reader.pages)

    if n_pages == 0:
        print("Error: input PDF has no pages.", file=sys.stderr)
        sys.exit(1)

    order, total = build_booklet_order(n_pages)
    n_sheets = total // 2  # each tuple in order = one side = one sheet face

    print(f"Input pages : {n_pages}")
    print(f"Padded to   : {total} pages ({total - n_pages} blank pages added)")
    print(f"Output sheets: {len(order)} sides ({len(order) // 2} physical sheets)")

    writer = PdfWriter()

    for i, (left_idx, right_idx) in enumerate(order):
        is_back = (i % 2 == 1)
        if rotate_backs and is_back:
            left_idx, right_idx = right_idx, left_idx
        place_page_on_sheet(writer, left_idx, right_idx, reader, rotate=rotate_backs and is_back)

    with open(output_path, "wb") as f:
        writer.write(f)

    print(f"Written to  : {output_path}")


def main():
    parser = argparse.ArgumentParser(
        description="Generate a saddle-stitch booklet PDF from an A4 portrait PDF."
    )
    parser.add_argument("input", help="Input A4 portrait PDF")
    parser.add_argument("output", help="Output A4 landscape booklet PDF")
    parser.add_argument(
        "--no-pad",
        action="store_true",
        help="Do not pad page count to a multiple of 4 (may produce incomplete last sheet)",
    )
    parser.add_argument(
        "--no-rotate-backs",
        action="store_true",
        help="Do not rotate back sides 180° (use if your printer handles this automatically)",
    )
    args = parser.parse_args()

    if not Path(args.input).exists():
        print(f"Error: file not found: {args.input}", file=sys.stderr)
        sys.exit(1)

    generate_booklet(args.input, args.output, pad=not args.no_pad, rotate_backs=not args.no_rotate_backs)


if __name__ == "__main__":
    main()