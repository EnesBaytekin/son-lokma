#!/usr/bin/env python3
"""Generate placeholder PNG assets for son-lokma.

These are temporary boxes that will later be replaced with real art.
The file layout is final, so dropping real PNGs with the same names
is enough to swap them in:

    assets/plate.png
    assets/fork.png
    assets/crumb.png   (white circle, tinted at runtime via modulate)
    assets/foods/<food>/<food>_<i>.png   (i == 0 full ... last index near empty)
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = "/home/imns/son-lokma"
ASSETS = os.path.join(ROOT, "assets")

# name, fill color (RGBA), number of visual states
FOODS = [
    ("sarma", (74, 124, 63, 255), 5),    # yaprak sarmasi
    ("kisir", (201, 106, 42, 255), 4),   # kisir
    ("kek", (107, 66, 38, 255), 3),      # islak kek
]


def get_font(size):
    candidates = [
        "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/liberation/LiberationSans-Bold.ttf",
        "/usr/share/fonts/liberation/LiberationSans-Regular.ttf",
    ]
    for path in candidates:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default(size)


def draw_plate():
    w, h = 1000, 520
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse((40, 40, w - 40, h - 40),
              fill=(225, 225, 225, 255),
              outline=(150, 150, 150, 255),
              width=6)
    d.ellipse((120, 92, w - 120, h - 92),
              fill=(242, 242, 242, 255),
              outline=(205, 205, 205, 255),
              width=3)
    return img


def draw_fork():
    """Horizontal fork: tines on the left, handle on the right."""
    w, h = 360, 90
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    silver = (185, 190, 200, 255)
    dark = (140, 145, 155, 255)
    # handle
    d.rounded_rectangle((180, 40, 352, 50), radius=5,
                        fill=silver, outline=dark, width=1)
    # neck
    d.polygon([(180, 40), (180, 50), (140, 30), (140, 60)], fill=silver)
    # 4 tines
    for i in range(4):
        top = 26 + i * 11
        d.rounded_rectangle((50, top, 140, top + 5), radius=2, fill=silver)
    return img


def draw_crumb():
    """Small white circle, tinted at runtime to match the food it belongs to."""
    size = 24
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse((3, 3, 21, 21), fill=(255, 255, 255, 255))
    return img


def draw_food(name, color, state_count, idx):
    """idx 0 = full, state_count-1 = last bite left."""
    size = 240
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    bites_left = state_count - idx
    fill = bites_left / state_count

    # bowl outline
    box = (30, 42, 210, 196)
    d.rounded_rectangle(box, radius=24, outline=(205, 205, 205, 255), width=4)

    # filled portion, bottom-up
    top = box[3] - int((box[3] - box[1]) * fill)
    top = max(top, box[1])
    d.rounded_rectangle((box[0] + 3, top, box[2] - 3, box[3] - 3),
                        radius=18, fill=color)

    # labels
    font_big = get_font(40)
    font_small = get_font(28)
    d.text((size // 2, 14), name.upper(), font=font_big,
           fill=(40, 40, 40, 255), anchor="ma")
    d.text((size // 2, box[3] + 12), "%d/%d" % (bites_left, state_count),
           font=font_small, fill=(40, 40, 40, 255), anchor="ma")

    return img


def main():
    os.makedirs(ASSETS, exist_ok=True)
    draw_plate().save(os.path.join(ASSETS, "plate.png"))
    draw_fork().save(os.path.join(ASSETS, "fork.png"))
    draw_crumb().save(os.path.join(ASSETS, "crumb.png"))

    for name, color, count in FOODS:
        out_dir = os.path.join(ASSETS, "foods", name)
        os.makedirs(out_dir, exist_ok=True)
        for idx in range(count):
            draw_food(name, color, count, idx).save(
                os.path.join(out_dir, "%s_%d.png" % (name, idx)))

    print("placeholder assets written to", ASSETS)


if __name__ == "__main__":
    main()
