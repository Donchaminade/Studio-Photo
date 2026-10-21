"""Prépare l’icône launcher : blanc extérieur retiré, centre conservé, ombre légère."""
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "logos" / "image.png"
DST = ROOT / "assets" / "logos" / "pro.png"


def main() -> None:
    im = Image.open(SRC).convert("RGBA")
    arr = np.array(im)
    h, w = arr.shape[:2]

    nonwhite = ~((arr[:, :, 0] > 248) & (arr[:, :, 1] > 248) & (arr[:, :, 2] > 248))
    ys, xs = np.where(nonwhite)
    cx = (float(xs.min()) + float(xs.max())) / 2.0
    cy = (float(ys.min()) + float(ys.max())) / 2.0
    radius = np.sqrt((xs.astype(float) - cx) ** 2 + (ys.astype(float) - cy) ** 2).max() + 3

    yy, xx = np.ogrid[:h, :w]
    outside = (xx - cx) ** 2 + (yy - cy) ** 2 > radius ** 2
    arr[outside] = (0, 0, 0, 0)

    pad = 8
    y0, y1 = max(int(cy - radius) - pad, 0), min(int(cy + radius) + pad + 1, h)
    x0, x1 = max(int(cx - radius) - pad, 0), min(int(cx + radius) + pad + 1, w)
    cropped = Image.fromarray(arr[y0:y1, x0:x1])

    out_size = 1024
    target = int(out_size * 0.74)
    logo = cropped.resize((target, target), Image.Resampling.LANCZOS)

    alpha = logo.split()[3]
    shadow = Image.new("RGBA", logo.size, (0, 0, 0, 0))
    shadow.putalpha(alpha.point(lambda a: int(a * 0.22)))
    shadow = shadow.filter(ImageFilter.GaussianBlur(14))

    canvas = Image.new("RGBA", (out_size, out_size), (0, 0, 0, 0))
    ox = (out_size - target) // 2
    oy = (out_size - target) // 2
    canvas.paste(shadow, (ox, oy + 8), shadow)
    canvas.paste(logo, (ox, oy), logo)
    canvas.save(DST)
    print(f"Wrote {DST} {canvas.size} radius={radius:.1f}")


if __name__ == "__main__":
    main()
