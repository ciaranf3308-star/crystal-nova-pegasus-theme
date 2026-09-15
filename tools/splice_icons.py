#!/usr/bin/env python3
"""Phase 1.6 production icon builder for the Crystal Nova Pegasus theme.

Extracts individual console icons from a supplier sprite sheet (3x2 grid,
transparent PNG) and normalizes each onto a 512x512 RGBA canvas:

  - crop on the visible alpha bounds of the largest connected component
    (stray pixels outside the intended object are discarded)
  - small consistent transparent pad retained around the object
  - longest side (object + pad) scaled to 400px  (~78% of the canvas,
    inside the 75-82% target band); aspect ratio preserved, no stretching
  - optical centering: the alpha-weighted centroid of the artwork is
    placed at (256, 250) -- visual mass balanced, with a slight upward
    bias so bottom-heavy hardware doesn't look sunk
  - no sharpening, recoloring, regeneration, or tracing: source pixels
    are only resampled (LANCZOS) during the single scale step

Usage:
    splice_icons.py <sheet.png> <outdir>

The six output names come from the module-level ORDER list (top row
left-to-right, then bottom row left-to-right); override it before calling
main() when processing a different sheet.
"""
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

CANVAS = 512
TARGET_SIDE = 400   # ~78% of canvas
PAD = 6             # transparent breathing room kept around the tight crop
OPTICAL_CENTER = (256, 250)

# Sheet 1 default; override per sheet (reading order: top row L->R, bottom L->R).
ORDER = ["gba", "snes", "ps1", "n64", "dreamcast", "psp"]


def load_rgba(path):
    return Image.open(path).convert("RGBA")


def components_by_size(alpha):
    """Label 8-connected components of the opaque mask, largest first."""
    mask = alpha > 8
    lab, n = ndimage.label(mask, structure=np.ones((3, 3), dtype=int))
    sizes = ndimage.sum(mask, lab, range(1, n + 1))
    order = np.argsort(sizes)[::-1]
    return lab, [int(i + 1) for i in order]


def reading_order(boxes):
    """Sort bounding boxes into a 3-col x 2-row reading order by centroid."""
    cx = [(b[0] + b[2]) / 2 for b in boxes]
    cy = [(b[1] + b[3]) / 2 for b in boxes]
    idx = sorted(range(len(boxes)), key=lambda i: cy[i])
    top = sorted(idx[:3], key=lambda i: cx[i])
    bottom = sorted(idx[3:6], key=lambda i: cx[i])
    return top + bottom


def tight_component_crop(im, lab, comp_id):
    """Crop the single component on its visible alpha bounds (stray-safe)."""
    ys, xs = np.nonzero(lab == comp_id)
    x0, x1 = xs.min(), xs.max() + 1
    y0, y1 = ys.min(), ys.max() + 1
    return im.crop((x0, y0, x1, y1))


def alpha_centroid(im):
    """Alpha-weighted centroid of an RGBA image, in its own pixel coords."""
    a = np.asarray(im, dtype=np.float64)[:, :, 3]
    total = a.sum()
    if total <= 0:
        return im.width / 2, im.height / 2
    ys, xs = np.mgrid[0:im.height, 0:im.width]
    return (xs * a).sum() / total, (ys * a).sum() / total


def normalize_icon(crop):
    """Place the artwork on a 512x512 canvas per the Phase 1.6 spec."""
    # Consistent transparent margin, then scale longest side to TARGET_SIDE.
    w, h = crop.size
    pw, ph = w + 2 * PAD, h + 2 * PAD
    scale = TARGET_SIDE / max(pw, ph)
    nw, nh = max(1, round(pw * scale)), max(1, round(ph * scale))
    padded = Image.new("RGBA", (pw, ph), (0, 0, 0, 0))
    padded.alpha_composite(crop, (PAD, PAD))
    scaled = padded.resize((nw, nh), Image.LANCZOS)

    # Optical centering via the alpha centroid.
    ccx, ccy = alpha_centroid(scaled)
    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    ox = int(round(OPTICAL_CENTER[0] - ccx))
    oy = int(round(OPTICAL_CENTER[1] - ccy))
    canvas.alpha_composite(scaled, (ox, oy))
    return canvas


def main():
    sheet_path, outdir = sys.argv[1], sys.argv[2]
    os.makedirs(outdir, exist_ok=True)
    im = load_rgba(sheet_path)
    print(f"sheet: {im.size}")
    lab, by_size = components_by_size(np.asarray(im)[:, :, 3])
    if len(by_size) < 6:
        sys.exit(f"expected 6 objects, found {len(by_size)}")
    boxes = []
    for cid in by_size[:6]:
        ys, xs = np.nonzero(lab == cid)
        boxes.append((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    ordered = reading_order(boxes)
    assert len(ORDER) == 6, "ORDER must name exactly 6 icons"
    for slot, name in enumerate(ORDER):
        cid = by_size[:6][ordered[slot]]
        crop = tight_component_crop(im, lab, cid)
        icon = normalize_icon(crop)
        out = os.path.join(outdir, f"{name}.png")
        icon.save(out)
        print(f"{name:12s} crop={crop.size[0]}x{crop.size[1]} -> {out}")
    print("done")


if __name__ == "__main__":
    main()
