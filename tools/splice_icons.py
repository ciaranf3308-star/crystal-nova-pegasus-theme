#!/usr/bin/env python3
"""Splice the 6 console logos from the supplier sheet into theme icon pairs.

Steps per console:
  1. Detect connected non-black components -> 6 bounding boxes, reading order.
  2. Crop with margin.
  3. Flood-fill the border-connected near-black background -> transparency
     (interior dark pixels of the artwork are preserved).
  4. Save normal variant (original icy-blue artwork, transparent bg).
  5. Save _selected variant: luminance remapped onto a dark-navy ramp so the
     illustration reads on the cream selected tile.

Usage:
    python3 tools/splice_icons.py <sheet.png> <assets/icons/>
"""
import sys
from PIL import Image, ImageDraw
import numpy as np

ORDER = ["gba", "snes", "ps1", "n64", "dreamcast", "psp"]
MARGIN = 14
BG_THRESH = 40          # flood-fill tolerance for near-black background
MASK_THRESH = 25        # what counts as "content" for component detection

NAVY_DARK = np.array([22, 38, 63], dtype=np.float32)     # #16263f
NAVY_LIGHT = np.array([126, 158, 188], dtype=np.float32)  # icy steel highlight


def find_boxes(img):
    a = np.asarray(img.convert("RGB")).astype(np.int32)
    mask = a.max(axis=2) > MASK_THRESH
    try:
        from scipy.ndimage import label
        lab, n = label(mask)
    except ImportError:
        sys.exit("scipy is required: pip install scipy")
    boxes = []
    for i in range(1, n + 1):
        ys, xs = np.nonzero(lab == i)
        if len(xs) < 500:      # ignore specks / text dots
            continue
        boxes.append((xs.min(), ys.min(), xs.max(), ys.max(), len(xs)))
    boxes.sort(key=lambda b: b[4], reverse=True)
    boxes = boxes[:6]
    # reading order: top row then bottom row, left to right within each row
    boxes.sort(key=lambda b: b[1])
    top = sorted([b for b in boxes if b[1] < img.height / 2], key=lambda b: b[0])
    bot = sorted([b for b in boxes if b[1] >= img.height / 2], key=lambda b: b[0])
    ordered = top + bot
    assert len(ordered) == 6, f"expected 6 consoles, found {len(ordered)}"
    return ordered


def key_out_background(crop):
    """Flood-fill border-connected background -> transparent. Returns RGBA."""
    rgb = crop.convert("RGB")
    keyed = rgb.copy()
    ImageDraw.floodfill(keyed, (0, 0), (255, 0, 255), thresh=BG_THRESH)
    # also seed the other three corners in case (0,0) touched art
    w, h = keyed.size
    for seed in [(w - 1, 0), (0, h - 1), (w - 1, h - 1)]:
        ImageDraw.floodfill(keyed, seed, (255, 0, 255), thresh=BG_THRESH)
    a = np.asarray(keyed)
    alpha = np.all(a != [255, 0, 255], axis=2).astype(np.uint8) * 255
    rgba = np.dstack([np.asarray(rgb), alpha])
    return Image.fromarray(rgba, "RGBA")


def navy_variant(rgba):
    """Remap luminance onto a dark-navy ramp; keep original alpha."""
    a = np.asarray(rgba).astype(np.float32)
    rgb, alpha = a[..., :3], a[..., 3:4]
    lum = (0.2126 * rgb[..., 0] + 0.7152 * rgb[..., 1]
           + 0.0722 * rgb[..., 2]) / 255.0
    ramp = NAVY_DARK[None, None, :] + (NAVY_LIGHT - NAVY_DARK)[None, None, :] \
        * lum[..., None]
    out = np.dstack([np.clip(ramp, 0, 255), alpha]).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def main():
    sheet_path, out_dir = sys.argv[1], sys.argv[2]
    img = Image.open(sheet_path)
    print(f"sheet: {img.size}")
    boxes = find_boxes(img)
    for name, (x0, y0, x1, y1, _area) in zip(ORDER, boxes):
        x0 = max(0, x0 - MARGIN); y0 = max(0, y0 - MARGIN)
        x1 = min(img.width, x1 + MARGIN); y1 = min(img.height, y1 + MARGIN)
        print(f"{name:10s} box=({x0},{y0})-({x1},{y1}) size={x1-x0}x{y1-y0}")
        crop = img.crop((x0, y0, x1, y1))
        normal = key_out_background(crop)
        normal.save(f"{out_dir}/{name}.png")
        navy_variant(normal).save(f"{out_dir}/{name}_selected.png")
    print("done")


if __name__ == "__main__":
    main()
