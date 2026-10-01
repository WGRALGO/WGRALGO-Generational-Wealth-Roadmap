#!/usr/bin/env python3
"""Build the launcher icons and splash images from assets/icon.png.

- Adaptive icon: the logo on solid black, sized so the badge stays inside
  the 72dp circle mask (round, squircle, and square launchers).
- Android 12+ system splash (drawable-nodpi/splash_icon.jpg): the logo sized
  to fill the 160dp splash circle.
- Legacy splash.png files: the logo large and centered on black.
- www/logo.jpg: the in-app logo.
"""
import glob, os, math
# Run from the repo root: python3 tools/build-icons.py
RES = "android/app/src/main/res/"
from PIL import Image
logo = Image.open("assets/icon.png").convert("RGB")
# Clamp near-black to pure black so the logo blends into black backgrounds
logo = logo.point(lambda v: v)
_px = logo.load()
for _y in range(logo.size[1]):
    for _x in range(logo.size[0]):
        if max(_px[_x, _y]) <= 8: _px[_x, _y] = (0, 0, 0)
W = logo.size[0]; px = logo.load(); c = (W-1)/2
R = max(math.hypot(x-c, y-c) for y in range(W) for x in range(W) if max(px[x,y]) > 24) / W
print("R", round(R,3))
def canvas(size, logo_w):
    im = Image.new("RGB", (size, size), (0,0,0))
    lw = round(logo_w); l = logo.resize((lw, lw), Image.LANCZOS)
    off = (size - lw)//2
    im.paste(l, (off, off)) if lw <= size else im.paste(l.crop(((lw-size)//2,)*2+((lw+size)//2,)*2), (0,0))
    return im
dens = {"ldpi":0.75,"mdpi":1,"hdpi":1.5,"xhdpi":2,"xxhdpi":3,"xxxhdpi":4}
for d, f in dens.items():
    dd = f"mipmap-{d}"
    fg = round(108*f); canvas(fg, fg*(35.5/R)/108).save(RES + f"{dd}/ic_launcher_foreground.png")
    Image.new("RGB",(fg,fg),(0,0,0)).save(RES + f"{dd}/ic_launcher_background.png")
    lg = round(48*f)
    canvas(lg, lg*0.495/R).save(RES + f"{dd}/ic_launcher.png")
    canvas(lg, lg*0.495/R).save(RES + f"{dd}/ic_launcher_round.png")
os.makedirs(RES + "drawable-nodpi", exist_ok=True)
canvas(768, 768*(79/R)/240).save(RES + "drawable-nodpi/splash_icon.jpg", quality=92)
for p in glob.glob(RES + "drawable*/splash.png"):
    w, h = Image.open(p).size
    im = Image.new("RGB",(w,h),(0,0,0)); s = round(min(w,h)*0.8)
    im.paste(logo.resize((s,s), Image.LANCZOS), ((w-s)//2,(h-s)//2))
    im.quantize(256).save(p, optimize=True)
logo.resize((640,640), Image.LANCZOS).save("www/logo.jpg", quality=90)
