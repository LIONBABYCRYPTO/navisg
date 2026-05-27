"""Generate Nāvisg v1.2.0 app store graphics — Feature Graphic, Screenshot, Keyword Banner."""
import subprocess, sys, os
from PIL import Image, ImageDraw, ImageFont

OUT = "/Users/lordy/navisg"
W, H = 1080, 1920  # phone screenshot
BG_DARK = (15, 23, 42)
CARD = (25, 38, 62)
GOLD = (255, 183, 77)
GREEN = (76, 175, 80)
TEAL = (0, 150, 136)
PURPLE = (156, 39, 176)
RED = (244, 67, 54)
ORANGE = (255, 152, 0)
BLUE = (33, 150, 243)
GREY = (120, 130, 150)
WHITE = (255, 255, 255)
STATUS_GREEN = (76, 175, 80)

def load_font(size, bold=False):
    paths = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/HelveticaNeue.ttc",
    ]
    for p in paths:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()

def rrect(draw, xy, r, fill, outline=None, width=0):
    x0, y0, x1, y1 = xy
    draw.rounded_rectangle(xy, radius=r, fill=fill, outline=outline, width=width)

def gen_screenshot():
    img = Image.new("RGB", (W, H), BG_DARK)
    draw = ImageDraw.Draw(img)
    font_sm = load_font(22)
    font_md = load_font(30)
    font_lg = load_font(38, bold=True)
    font_xl = load_font(48, bold=True)

    # --- Status bar ---
    for i, (icon, x) in enumerate([("9:41", 40), ("▂▄▆█", 210), ("5G", 330), ("🔋84%", 400)]):
        draw.text((x, 16), icon, fill=WHITE if i != 1 else GREY, font=font_sm)

    # --- Header bar ---
    draw.rectangle((0, 56, W, 140), fill=CARD)
    # Back arrow
    draw.text((24, 74), "◀", fill=WHITE, font=font_lg)
    draw.text((80, 78), "Map", fill=GOLD, font=font_md)
    # Right icons
    draw.text((900, 74), "🗺️", fill=WHITE, font=font_lg)
    draw.text((1000, 74), "⚙️", fill=WHITE, font=font_lg)

    # --- Map area ---
    # Simulate a map with roads and markers
    # Background
    map_bg = (30, 50, 40)
    draw.rectangle((0, 140, W, 860), fill=map_bg)
    # Roads (light grey lines)
    road_color = (55, 75, 65)
    for y in range(200, 850, 60):
        draw.line((0, y, W, y), fill=road_color, width=2)
    for x in range(0, W, 80):
        draw.line((x, 140, x, 860), fill=road_color, width=2)

    # Water body top-right
    draw.ellipse((750, 180, 1000, 380), fill=(20, 60, 70))

    # Bus stop markers
    stops_pos = [(200, 320), (400, 280), (600, 380), (300, 500), (550, 550), (700, 450), (250, 650), (480, 720), (650, 680)]
    for sx, sy in stops_pos:
        draw.ellipse((sx-12, sy-12, sx+12, sy+12), fill=TEAL, outline=WHITE, width=2)
        draw.text((sx-4, sy-7), "🚌", fill=WHITE, font=font_sm)

    # Selected stop (orange)
    sel_x, sel_y = 400, 280
    draw.ellipse((sel_x-16, sel_y-16, sel_x+16, sel_y+16), fill=ORANGE, outline=WHITE, width=3)
    draw.text((sel_x-5, sel_y-9), "🚌", fill=WHITE, font=font_sm)

    # Nearby GPS dot
    gps_x, gps_y = 500, 450
    # Outer ring
    for r in [25, 18]:
        draw.ellipse((gps_x-r, gps_y-r, gps_x+r, gps_y+r), outline=BLUE, width=2)
    draw.ellipse((gps_x-8, gps_y-8, gps_x+8, gps_y+8), fill=BLUE, outline=WHITE, width=2)

    # Zoom controls right side
    zoomy = 570
    for label, yoff in [("+", 0), ("-", 56), ("📍", 112)]:
        rrect(draw, (990, zoomy+yoff, 1050, zoomy+yoff+44), 22, CARD, WHITE, 1)
        draw.text((1006, zoomy+yoff+6), label, fill=WHITE, font=font_md)

    # --- Arrival bottom sheet ---
    sheet_y = 860
    rrect(draw, (0, sheet_y, W, H), 20, (18, 28, 48))
    # Handle bar
    rrect(draw, (W//2-20, sheet_y+10, W//2+20, sheet_y+18), 4, GREY)

    # Stop header
    rrect(draw, (24, sheet_y+30, 100, sheet_y+58), 8, (40, 60, 90))
    draw.text((30, sheet_y+33), "83121", fill=GOLD, font=font_sm)
    draw.text((114, sheet_y+33), "Marina Bay Stn", fill=WHITE, font=font_md)
    draw.text((1000, sheet_y+33), "✕", fill=GREY, font=font_md)

    # Divider
    draw.line((24, sheet_y+72, W-24, sheet_y+72), fill=(40, 45, 60), width=1)

    # Bus service rows
    services = [
        ("97", "SBST", "Arr", "6m", "15m", RED, GREEN),
        ("400", "SMRT", "2m", "9m", "—", PURPLE, ORANGE),
        ("133", "SBST", "5m", "12m", "25m", RED, None),
        ("857", "TTS", "Arr", "8m", "—", ORANGE, GREEN),
        ("166", "SBST", "1m", "7m", "18m", RED, None),
    ]
    for i, (sno, op, t1, t2, t3, color, special_color) in enumerate(services):
        row_y = sheet_y + 86 + i * 42
        # Service badge
        rrect(draw, (24, row_y, 72, row_y+32), 6, (color[0]//3+10, color[1]//3+10, color[2]//3+10))
        draw.text((32, row_y+4), sno, fill=color, font=font_sm)

        # Arrivals
        arrivals = [("1st", t1, GREEN if t1 == "Arr" else ORANGE if "m" in t1 and int(t1.replace("m","")) <= 3 else WHITE),
                    ("2nd", t2, ORANGE if "m" in t2 and int(t2.replace("m","")) <= 3 else WHITE),
                    ("3rd", t3, GREY if t3 == "—" else WHITE)]
        for j, (label, time, tcolor) in enumerate(arrivals):
            x = 90 + j * 100
            draw.text((x, row_y), label, fill=GREY, font=load_font(16))
            draw.text((x, row_y+14), time, fill=tcolor, font=font_sm)

        # Wheelchair icon if applicable
        if special_color == GREEN:
            draw.text((390, row_y+4), "♿", fill=BLUE, font=font_sm)

        # Route link icon
        draw.text((940, row_y+4), "🗺️", fill=GREY, font=font_sm)

    # --- Bottom nav bar ---
    nav_y = H - 80
    draw.rectangle((0, nav_y, W, H), fill=(10, 18, 35))
    nav_items = [
        ("⭐", "Saved", False),
        ("🗺️", "Map", True),
        ("🅿️", "Park", False),
        ("🚇", "MRT", False),
        ("⚠️", "Traffic", False),
    ]
    spacing = W / 5
    for i, (icon, label, active) in enumerate(nav_items):
        nx = int(i * spacing + spacing/2)
        draw.text((nx-12, nav_y+8), icon, fill=GOLD if active else GREY, font=font_lg)
        draw.text((nx-24, nav_y+46), label, fill=GOLD if active else GREY, font=load_font(18))

    # --- Settings FAB ---
    rrect(draw, (W-68, H-140, W-16, H-88), 26, CARD)
    draw.text((W-52, H-124), "⚙️", fill=WHITE, font=font_lg)

    # --- Nearby list (collapsed card top) ---
    near_y = 170
    rrect(draw, (12, near_y, 360, near_y+38), 10, CARD)
    draw.text((24, near_y+6), "📍 Nearby Stops (15)", fill=GREEN, font=font_sm)
    draw.text((330, near_y+6), "✕", fill=GREY, font=font_sm)

    # Save to file
    path = f"{OUT}/screenshot_1.png"
    img.save(path)
    print(f"Screenshot saved: {path} ({os.path.getsize(path)//1024}KB)")
    return path

if __name__ == "__main__":
    gen_screenshot()
