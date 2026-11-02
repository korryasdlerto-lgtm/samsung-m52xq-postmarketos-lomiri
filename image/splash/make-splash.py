#!/usr/bin/env python3
# убунтутач24/003: images of the Plymouth theme m52xq-ubuntu-touch (the Ubuntu Touch boot splash: pink background,
# white "ubuntu touch" logo, 5 dots). Usage: make-splash.py <theme dir>
import math, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter
out = sys.argv[1]
W, H = 1080, 2400
F = '/usr/share/fonts/truetype/ubuntu/'

# background: violet (left/top) -> pink (right/bottom), with soft lighter facets like the UT splash
bg = Image.new('RGB', (W, H))
a, b = (178, 28, 182), (236, 20, 140)
px = bg.load()
for y in range(H):
    for x in range(W):
        t = min(1.0, max(0.0, (x / W) * 0.55 + (y / H) * 0.45))
        px[x, y] = tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))
fac = Image.new('RGBA', (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(fac)
d.polygon([(0, 0), (W * 0.62, 0), (0, H * 0.42)], fill=(255, 255, 255, 14))
d.polygon([(W, H * 0.30), (W, H), (W * 0.25, H)], fill=(255, 255, 255, 12))
d.polygon([(W * 0.35, H * 0.55), (W, H * 0.20), (W, H * 0.62)], fill=(80, 0, 90, 18))
bg = Image.alpha_composite(bg.convert('RGBA'), fac).convert('RGB')
bg.save(out + '/background.png', optimize=True)

# logo: "ubuntu" (Ubuntu Medium) + circle of friends, "touch" under the right end
lw, lh = 680, 260
logo = Image.new('RGBA', (lw * 2, lh * 2), (0, 0, 0, 0))   # drawn at 2x, scaled down for smooth edges
d = ImageDraw.Draw(logo)
fu2 = ImageFont.truetype(F + 'Ubuntu-M.ttf', 300)
ft2 = ImageFont.truetype(F + 'Ubuntu-R.ttf', 140)
d.text((10, 0), 'ubuntu', font=fu2, fill='white')
uw = d.textsize('ubuntu', font=fu2)[0]
# circle of friends (registered-mark position)
cx, cy, r = 10 + uw + 50, 95, 40
d.ellipse((cx - r, cy - r, cx + r, cy + r), outline='white', width=12)
for k in range(3):
    ang = math.radians(-90 + 120 * k + 30)
    hx, hy = cx + r * math.cos(ang), cy + r * math.sin(ang)
    d.ellipse((hx - 15, hy - 15, hx + 15, hy + 15), fill='white')
tw = d.textsize('touch', font=ft2)[0]
d.text((10 + uw - tw + 10, 270), 'touch', font=ft2, fill='white')
bb = logo.getbbox(); logo = logo.crop(bb)
logo = logo.resize((logo.width // 2, logo.height // 2), Image.LANCZOS)
logo.save(out + '/logo.png', optimize=True)

# dots: dim and bright
for name, col, rr in (('dot-off.png', (255, 190, 120, 150), 9), ('dot-on.png', (255, 255, 255, 255), 11)):
    im = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    ImageDraw.Draw(im).ellipse((16 - rr, 16 - rr, 16 + rr, 16 + rr), fill=col)
    im.save(out + '/' + name)
