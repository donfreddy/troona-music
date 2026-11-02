"""Compose the 1280x640 README and social preview banner from real app screenshots.

It reads screenshots/home.jpeg, player.jpeg and library.jpeg, plus
assets/images/app-logo-round.png, renders at 2x and downsamples.

Usage:
    pip install pillow
    python3 tool/make_banner.py . screenshots/banner.png
    python3 tool/make_banner.py . screenshots/banner.png --font /path/to/font.ttf

The default font is Helvetica Neue as shipped with macOS. A .ttc collection
gives the regular, medium and bold faces; a single .ttf is used for all three.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
parser.add_argument("root", help="repository root")
parser.add_argument("output", help="output PNG path")
parser.add_argument("--font", default="/System/Library/Fonts/HelveticaNeue.ttc")
args = parser.parse_args()

if not os.path.isfile(args.font):
    sys.exit(f"Font not found: {args.font}\nPass one with --font /path/to/font.ttf")

ROOT = args.root
OUT = args.output
S = 2  # supersampling factor
W, H = 1280 * S, 640 * S
ACCENT = (183, 156, 255)  # ColorPrimitives.accent


def font(size, index):
    """Loads a face from a .ttc collection, or the single face of a .ttf."""
    try:
        return ImageFont.truetype(args.font, size, index=index)
    except OSError:
        return ImageFont.truetype(args.font, size)

canvas = Image.new("RGB", (W, H), (7, 9, 14))

# Soft lilac glow behind the phones.
glow = Image.new("L", (W, H), 0)
ImageDraw.Draw(glow).ellipse((W * 0.50, H * 0.05, W * 1.05, H * 1.0), fill=110)
glow = glow.filter(ImageFilter.GaussianBlur(160 * S))
canvas.paste(Image.new("RGB", (W, H), (70, 45, 140)), (0, 0), glow)


def phone(path, height):
    shot = Image.open(path).convert("RGB")
    width = round(shot.width * height / shot.height)
    shot = shot.resize((width, height), Image.LANCZOS)
    radius = 26 * S
    mask = Image.new("L", (width, height), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, width - 1, height - 1), radius, fill=255)
    framed = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    framed.paste(shot, (0, 0), mask)
    ImageDraw.Draw(framed).rounded_rectangle(
        (0, 0, width - 1, height - 1), radius, outline=(255, 255, 255, 40), width=2 * S
    )
    return framed


def drop(img, x, y):
    shadow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(shadow).rounded_rectangle(
        (x, y + 18 * S, x + img.width, y + img.height + 18 * S), 26 * S, fill=170
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(28 * S))
    canvas.paste((0, 0, 0), (0, 0), shadow)
    canvas.paste(img, (x, y), img)


side_h, main_h = 470 * S, 540 * S
left = phone(f"{ROOT}/screenshots/home.jpeg", side_h)
right = phone(f"{ROOT}/screenshots/library.jpeg", side_h)
main = phone(f"{ROOT}/screenshots/player.jpeg", main_h)

cx = 935 * S
gap = 150 * S
drop(left, cx - gap - left.width // 2, (H - side_h) // 2 + 10 * S)
drop(right, cx + gap - right.width // 2, (H - side_h) // 2 + 10 * S)
drop(main, cx - main.width // 2, (H - main_h) // 2)

# Text block.
d = ImageDraw.Draw(canvas)
x = 72 * S
logo = Image.open(f"{ROOT}/assets/images/app-logo-round.png").convert("RGBA")
logo = logo.resize((88 * S, 88 * S), Image.LANCZOS)
canvas.paste(logo, (x, 178 * S), logo)

title = font(76 * S, 1)  # Bold
body = font(27 * S, 0)  # Regular
small = font(21 * S, 10)  # Medium

d.text((x, 290 * S), "Troona", font=title, fill=(255, 255, 255))
d.text((x, 384 * S), "Offline-first music player", font=body, fill=(235, 235, 245))
d.text((x, 420 * S), "for Android", font=body, fill=(235, 235, 245))
d.text((x, 476 * S), "No account. No ads. No analytics.", font=small, fill=ACCENT)

canvas.resize((1280, 640), Image.LANCZOS).save(OUT, optimize=True)
print(OUT)
