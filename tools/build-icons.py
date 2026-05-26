#!/usr/bin/env python3
"""Build Android launcher icons + splash from the Generational Wealth Roadmap logo.

- Full-bleed legacy icons (no white square padding).
- Adaptive icon with solid black background + oversized logo foreground (safe-zone aware).
- Splash on solid black with the logo centered, large but not edge-to-edge.
"""
import os
from PIL import Image

SRC_LOGO = os.path.expanduser('~/Desktop/generational-wealth-roadmap logo.png')
ANDROID_RES = os.path.expanduser(
    '~/generational-wealth-roadmap/android/app/src/main/res')
WWW_IMG = os.path.expanduser(
    '~/generational-wealth-roadmap/www/img/logo.png')
ASSETS_DIR = os.path.expanduser('~/generational-wealth-roadmap/assets')

LAUNCHER_SIZES = {
    'mipmap-mdpi':    48,
    'mipmap-hdpi':    72,
    'mipmap-xhdpi':   96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

# Adaptive icon foreground is a 108dp canvas where the inner 72dp is the safe zone.
# We render the logo at ~72/108 of the canvas width on a transparent background.
ADAPTIVE_FG_RATIO = 0.72

# Splash sizes (drawable-port-*) — keep parity with reference apps using a single splash.png is enough,
# but generate several portrait sizes for crisp display on all densities.
SPLASH_SIZES = [
    ('drawable',              (480, 800)),
    ('drawable-port-mdpi',    (320, 480)),
    ('drawable-port-hdpi',    (480, 800)),
    ('drawable-port-xhdpi',   (720, 1280)),
    ('drawable-port-xxhdpi',  (960, 1600)),
    ('drawable-port-xxxhdpi', (1280, 1920)),
    ('drawable-land-mdpi',    (480, 320)),
    ('drawable-land-hdpi',    (800, 480)),
    ('drawable-land-xhdpi',  (1280, 720)),
    ('drawable-land-xxhdpi', (1600, 960)),
    ('drawable-land-xxxhdpi',(1920,1280)),
]


def load_logo() -> Image.Image:
    im = Image.open(SRC_LOGO).convert('RGBA')
    return im


def crop_square_cover(im: Image.Image) -> Image.Image:
    w, h = im.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    return im.crop((left, top, left + side, top + side))


def make_legacy_icon(logo_sq: Image.Image, size: int, round_mask: bool=False) -> Image.Image:
    """Full-bleed square (or round) icon. The logo fills the entire output."""
    icon = logo_sq.resize((size, size), Image.LANCZOS)
    if round_mask:
        mask = Image.new('L', (size, size), 0)
        from PIL import ImageDraw
        ImageDraw.Draw(mask).ellipse((0, 0, size, size), fill=255)
        out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        out.paste(icon, (0, 0), mask)
        return out
    return icon


def make_adaptive_foreground(logo_sq: Image.Image, size: int) -> Image.Image:
    """Transparent canvas with the logo centered at the safe-zone size."""
    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    inner = int(size * ADAPTIVE_FG_RATIO)
    fg = logo_sq.resize((inner, inner), Image.LANCZOS)
    pos = ((size - inner) // 2, (size - inner) // 2)
    canvas.paste(fg, pos, fg)
    return canvas


def make_adaptive_background(size: int) -> Image.Image:
    return Image.new('RGB', (size, size), (0, 0, 0))


def make_splash(logo_sq: Image.Image, w: int, h: int) -> Image.Image:
    canvas = Image.new('RGB', (w, h), (0, 0, 0))
    side = int(min(w, h) * 0.55)
    splash = logo_sq.resize((side, side), Image.LANCZOS)
    # Composite the logo (RGBA) onto the black background using the alpha mask.
    pos = ((w - side) // 2, (h - side) // 2)
    canvas.paste(splash, pos, splash)
    return canvas


def write_png(im: Image.Image, path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.save(path, 'PNG', optimize=True)


def main():
    logo = load_logo()
    logo_sq = crop_square_cover(logo)

    # www logo (used in HTML hero + topbar)
    write_png(logo_sq.resize((512, 512), Image.LANCZOS), WWW_IMG)

    # Asset reference copies
    os.makedirs(ASSETS_DIR, exist_ok=True)
    write_png(logo_sq.resize((1024, 1024), Image.LANCZOS), os.path.join(ASSETS_DIR, 'icon.png'))
    write_png(make_adaptive_foreground(logo_sq, 1024), os.path.join(ASSETS_DIR, 'icon-foreground.png'))
    write_png(make_adaptive_background(1024), os.path.join(ASSETS_DIR, 'icon-background.png'))

    # Legacy icons + adaptive layers for each density
    for folder, size in LAUNCHER_SIZES.items():
        base = os.path.join(ANDROID_RES, folder)
        write_png(make_legacy_icon(logo_sq, size, round_mask=False),
                  os.path.join(base, 'ic_launcher.png'))
        write_png(make_legacy_icon(logo_sq, size, round_mask=True),
                  os.path.join(base, 'ic_launcher_round.png'))
        # Adaptive layers expect 108dp at given density: dp_to_px = size * 108/48 ~ but
        # Android Studio convention is to use the same densitybucket size for layers as
        # the legacy icon size. We follow that for parity with the reference apps.
        write_png(make_adaptive_foreground(logo_sq, size),
                  os.path.join(base, 'ic_launcher_foreground.png'))
        bg = make_adaptive_background(size).convert('RGB')
        write_png(bg, os.path.join(base, 'ic_launcher_background.png'))

    # Splash images
    for folder, (w, h) in SPLASH_SIZES:
        write_png(make_splash(logo_sq, w, h),
                  os.path.join(ANDROID_RES, folder, 'splash.png'))

    print('OK: launcher icons + splash generated.')


if __name__ == '__main__':
    main()
