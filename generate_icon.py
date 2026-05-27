#!/usr/bin/env python3
"""Navisg app icon - FINAL v7: Super-sampled for smooth edges"""
from PIL import Image, ImageDraw
import os

# Render at 4x and downscale for smooth anti-aliasing
scale = 4
size = 1024
rsize = size * scale

img = Image.new('RGBA', (rsize, rsize), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

BG = (21, 101, 192)
GOLD = (255, 193, 7)
WHITE = (255, 255, 255)
DARK = (33, 33, 33)
WIN = (144, 202, 249)

r = lambda v: v * scale  # scale coordinates

# Background
draw.rounded_rectangle([0, 0, rsize, rsize], radius=r(180), fill=BG)
draw.ellipse([r(-60), r(-60), r(400), r(400)], fill=(30, 120, 210, 90))
draw.ellipse([r(680), r(500), r(1100), r(1000)], fill=(10, 60, 140, 60))

# Map Pin
cx, cy = r(512), r(490)
cr = r(300)
pin_h = r(80)

draw.ellipse([cx - cr, cy - cr, cx + cr, cy + cr], fill=WHITE)
py = cy + cr
draw.polygon([(cx - r(48), py - r(5)), (cx + r(48), py - r(5)), (cx, py + pin_h)], fill=WHITE)

# Gold border - thick and smooth
draw.ellipse([cx - cr + r(6), cy - cr + r(6), cx + cr - r(6), cy + cr - r(6)],
             outline=GOLD, width=r(9))
draw.line([(cx - r(42), py - r(3)), (cx - r(4), py + pin_h - r(4))], fill=GOLD, width=r(8))
draw.line([(cx + r(42), py - r(3)), (cx + r(4), py + pin_h - r(4))], fill=GOLD, width=r(8))

# Bus
bx, by = cx - r(115), cy - r(52)
bw, bh = r(230), r(112)
draw.rounded_rectangle([bx, by, bx + bw, by + bh], radius=r(14), fill=DARK)

for row_y in [by + r(10), by + r(52)]:
    for i in range(3):
        wx = bx + r(16) + i * r(68)
        draw.rounded_rectangle([wx, row_y, wx + r(54), row_y + r(30)], radius=r(6), fill=WIN)

draw.rectangle([bx + r(14), by + r(42), bx + bw - r(14), by + r(48)], fill=GOLD)

# Wheels with gold rim
for wx_off in [bx + r(42), bx + bw - r(42)]:
    draw.ellipse([wx_off, by + bh - r(2), wx_off + r(36), by + bh - r(2) + r(36)], fill=GOLD)
    draw.ellipse([wx_off + r(3), by + bh + r(1), wx_off + r(33), by + bh - r(1) + r(33)], fill=DARK)

# Highlight
draw.rounded_rectangle([bx + r(10), by + r(1), bx + bw - r(10), by + r(4)], radius=r(2), fill=(255, 255, 255, 30))

# Outer gold ring
draw.rounded_rectangle([r(5), r(5), rsize - r(6), rsize - r(6)], radius=r(177), outline=GOLD, width=r(6))
draw.rounded_rectangle([r(9), r(9), rsize - r(10), rsize - r(10)], radius=r(173), outline=WHITE, width=r(2))

# Downscale with Lanczos for smooth anti-aliasing
img_small = img.resize((size, size), Image.LANCZOS)
path = "/Users/lordy/navisg/app_icon_1024.png"
img_small.save(path, "PNG")
print(f"Icon saved: {path}")
print(f"Size: {os.path.getsize(path)} bytes")
