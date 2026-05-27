"""Generate Nāvisg v1.3.0 Play Store screenshot — Smart Map with layer toggles."""
import os
from PIL import Image, ImageDraw, ImageFont

OUT = "/Users/lordy/navisg"
W, H = 1080, 1920

DARK_BG = (10, 18, 35)
CARD_BG = (18, 28, 48)
GOLD = (255, 193, 7)
GREEN = (0, 200, 83)
TEAL = (0, 150, 136)
WHITE = (255, 255, 255)
GREY = (150, 160, 180)
SOFT_GREY = (100, 110, 130)
BLUE = (33, 150, 243)
ORANGE = (255, 152, 0)
RED_ERR = (244, 67, 54)

MRT_NS = (212, 46, 18)
MRT_EW = (0, 150, 69)
MRT_NE = (153, 0, 170)
MRT_CC = (255, 161, 0)
MRT_DT = (0, 94, 196)
MRT_TE = (157, 91, 37)

def load_font(size):
    paths = ["/System/Library/Fonts/SFNS.ttf", "/System/Library/Fonts/Helvetica.ttc", "/System/Library/Fonts/HelveticaNeue.ttc"]
    for p in paths:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()

def round_rect(draw, xy, r, fill, outline=None, width=0):
    draw.rounded_rectangle(xy, radius=r, fill=fill, outline=outline, width=width)

def gen_screenshot():
    img = Image.new("RGB", (W, H), DARK_BG)
    draw = ImageDraw.Draw(img)
    
    f_status = load_font(24)
    f_sm = load_font(22)
    f_med = load_font(30)
    f_lg = load_font(42)
    f_xl = load_font(56)

    # --- Status bar ---
    for y in range(56):
        draw.line((0, y, W, y), fill=(60 - y//2, 60 - y//2, 70 - y//2))
    draw.text((32, 14), "9:41", fill=WHITE, font=f_status)
    draw.text((370, 14), "5G", fill=WHITE, font=f_sm)
    draw.text((940, 14), "🔋 82%", fill=WHITE, font=f_sm)

    # --- Header ---
    round_rect(draw, (0, 56, W, 130), 0, CARD_BG)
    draw.text((80, 74), "Smart Map", fill=GOLD, font=f_med)
    # Route button
    round_rect(draw, (860, 72, 960, 112), 8, (30, 40, 65))
    draw.text((874, 78), "🗺️ Route", fill=WHITE, font=f_sm)

    # --- Map area ---
    map_top, map_bot = 130, 880
    for y in range(map_top, map_bot):
        t = (y - map_top) / (map_bot - map_top)
        draw.line((0, y, W, y), fill=(20 + int(t*8), 35 + int(t*12), 25 + int(t*8)))
    # Roads
    for y in range(map_top + 30, map_bot, 30):
        draw.line((0, y, W, y), fill=(40, 58, 48), width=2)
    for x in range(0, W, 55):
        draw.line((x, map_top, x, map_bot), fill=(40, 58, 48), width=1)
    # Water
    draw.ellipse((650, 180, 1050, 350), fill=(12, 35, 50))

    # ---- MRT markers (colored circles) ----
    mrt_data = [
        ("Marina Bay", MRT_NS, 340, 280), ("Raffles Place", MRT_EW, 320, 310),
        ("City Hall", MRT_NS, 280, 260), ("Dhoby Ghaut", MRT_NE, 250, 235),
        ("Bugis", MRT_EW, 230, 300), ("Tanjong Pagar", MRT_EW, 390, 340),
        ("Outram Park", MRT_EW, 430, 360), ("Chinatown", MRT_DT, 370, 345),
        ("Clarke Quay", MRT_NE, 340, 330), ("Little India", MRT_NE, 200, 220),
        ("HarbourFront", MRT_CC, 470, 420), ("Orchard", MRT_NS, 180, 190),
        ("Botanic Gdns", MRT_CC, 140, 170), ("Queenstown", MRT_EW, 520, 400),
    ]
    for name, color, mx, my in mrt_data:
        draw.ellipse((mx-13, my-13, mx+13, my+13), fill=color, outline=WHITE, width=3)
        # Small shadow
        draw.ellipse((mx-11, my-11, mx+11, my+11), fill=color)
        # Line label
        label = "NS" if color == MRT_NS else "EW" if color == MRT_EW else "NE" if color == MRT_NE else "CC" if color == MRT_CC else "DT"
        draw.text((mx-7, my-8), label, fill=WHITE, font=load_font(12))

    # ---- Bus stop markers (teal dots) ----
    bus_positions = [(410, 300), (300, 340), (370, 290), (440, 320), (260, 280),
                     (500, 350), (220, 250), (190, 290), (160, 310), (480, 300),
                     (550, 370), (620, 350), (700, 360), (140, 220), (350, 260)]
    for bx, by in bus_positions:
        draw.ellipse((bx-7, by-7, bx+7, by+7), fill=TEAL, outline=WHITE, width=2)

    # Selected bus stop (orange)
    sel_x, sel_y = 340, 280  # Near Marina Bay
    draw.ellipse((sel_x-16, sel_y-16, sel_x+16, sel_y+16), outline=ORANGE, width=3)
    draw.ellipse((sel_x-10, sel_y-10, sel_x+10, sel_y+10), fill=ORANGE, outline=WHITE, width=2)

    # GPS dot (blue)
    gx, gy = 500, 320
    for r in [24, 16, 7]:
        draw.ellipse((gx-r, gy-r, gx+r, gy+r),
                      outline=BLUE if r > 12 else None,
                      fill=BLUE if r <= 7 else None,
                      width=3 if r > 12 else 0)

    # --- Zoom controls (right) ---
    zx = W - 56
    for i, (label, col) in enumerate([("+", WHITE), ("−", WHITE), ("📍", BLUE)]):
        zy = 550 + i * 54
        round_rect(draw, (zx, zy, zx+42, zy+42), 21, CARD_BG, GREY, 1)
        draw.text((zx+13, zy+6), label, fill=col, font=f_med)

    # --- Layer toggle panel (bottom-left) ---
    panel_x, panel_y = 14, map_bot - 200
    round_rect(draw, (panel_x, panel_y, panel_x+90, panel_y+186), 14, CARD_BG, GREY, 1)
    
    layers = [
        ("🚌", "Bus", True, TEAL),
        ("🚇", "MRT", True, MRT_NE),
        ("🅿️", "Park", False, GREEN),
        ("⚠️", "Traf", False, RED_ERR),
    ]
    for i, (icon, label, active, color) in enumerate(layers):
        ly = panel_y + 12 + i * 42
        # Pill background
        bg = (color[0]//4+10, color[1]//4+10, color[2]//4+10) if active else (30, 35, 45)
        round_rect(draw, (panel_x+8, ly, panel_x+80, ly+34), 8, bg)
        draw.text((panel_x+14, ly+4), icon, fill=WHITE, font=load_font(18))
        draw.text((panel_x+40, ly+7), label, fill=WHITE if active else GREY, font=load_font(16))

    # --- Arrival bottom sheet ---
    sheet_y = 880
    round_rect(draw, (0, sheet_y, W, H), 24, (12, 20, 40))
    # Handle
    round_rect(draw, (W//2-25, sheet_y+10, W//2+25, sheet_y+18), 4, SOFT_GREY)

    # Stop header — MRT badge + bus stop code
    round_rect(draw, (16, sheet_y+30, 80, sheet_y+62), 8, MRT_NS)
    draw.text((24, sheet_y+36), "🚇", fill=WHITE, font=load_font(20))
    round_rect(draw, (90, sheet_y+30, 155, sheet_y+62), 8, (30, 45, 80))
    draw.text((96, sheet_y+36), "83121", fill=GOLD, font=f_sm)
    draw.text((164, sheet_y+36), "Marina Bay Stn", fill=WHITE, font=f_sm)
    draw.text((1020, sheet_y+36), "✕", fill=GREY, font=f_lg)

    # Divider
    draw.line((16, sheet_y+76, W-16, sheet_y+76), fill=(30, 40, 65), width=1)

    # Bus services
    services = [
        ("97", MRT_EW, "Arr", "6m", "15m"),
        ("400", MRT_DT, "2m", "9m", "—"),
        ("133", MRT_EW, "5m", "12m", "25m"),
        ("857", MRT_CC, "Arr", "8m", "—"),
        ("166", MRT_EW, "1m", "7m", "18m"),
    ]
    for i, (sno, color, t1, t2, t3) in enumerate(services):
        ry = sheet_y + 86 + i * 44
        # Service badge
        bg = (color[0]//4+8, color[1]//4+8, color[2]//4+8)
        round_rect(draw, (16, ry, 64, ry+34), 6, bg)
        draw.text((24, ry+5), sno, fill=color, font=f_sm)
        # Times
        col_x = 80
        for time, tc in [(t1, GREEN if t1=="Arr" else ORANGE),
                         (t2, ORANGE if "m" in t2 and int(t2.replace("m",""))<=3 else WHITE),
                         (t3, SOFT_GREY)]:
            draw.text((col_x, ry+4), time, fill=tc, font=f_med)
            col_x += 100
        # Wheelchair
        if i == 0:
            draw.text((400, ry+5), "♿", fill=BLUE, font=f_sm)
        # Route link
        round_rect(draw, (940, ry+4, 1000, ry+30), 6, (30, 40, 65))
        draw.text((948, ry+8), "🗺️", fill=GOLD, font=f_sm)
        # Divider
        draw.line((16, ry+40, W-16, ry+40), fill=(20, 30, 55), width=1)

    # --- Bottom nav bar ---
    nav_y = H - 80
    round_rect(draw, (0, nav_y, W, H), 0, (8, 14, 28))
    tabs = [("⭐", "Saved"), ("🗺️", "Map"), ("🅿️", "Park"), ("🚇", "MRT"), ("⚠️", "Traffic")]
    sp = W / 5
    for i, (icon, label) in enumerate(tabs):
        nx = int(sp * i + sp/2)
        col = GOLD if i == 1 else GREY
        draw.text((nx-14, nav_y+8), icon, fill=col, font=f_lg)
        draw.text((nx-24, nav_y+46), label, fill=col, font=load_font(18))

    # --- Settings FAB ---
    round_rect(draw, (W-66, H-140, W-14, H-88), 26, CARD_BG, WHITE, 1)
    draw.text((W-50, H-122), "⚙️", fill=WHITE, font=f_lg)

    # Save
    path = f"{OUT}/screenshot_1.png"
    img.save(path)
    print(f"Screenshot saved: {path} ({os.path.getsize(path)//1024}KB)")

if __name__ == "__main__":
    gen_screenshot()
