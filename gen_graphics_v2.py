"""Generate Nāvisg v1.2.0 Play Store graphics — Feature Graphic, Screenshot, Keyword Banner."""
import os
from PIL import Image, ImageDraw, ImageFont

OUT = "/Users/lordy/navisg"

# Color palette
DARK_BG = (10, 18, 35)
CARD_BG = (18, 28, 48)
NAVY = (14, 25, 45)
GOLD = (255, 193, 7)
GREEN = (0, 200, 83)
TEAL = (0, 150, 136)
PURPLE = (156, 39, 176)
RED = (244, 67, 54)
ORANGE = (255, 152, 0)
BLUE = (33, 150, 243)
LIGHT_BLUE = (3, 169, 244)
WHITE = (255, 255, 255)
GREY = (150, 160, 180)
SOFT_GREY = (100, 110, 130)

# MRT line colors
MRT_NS = (212, 46, 18)   # Red
MRT_EW = (0, 150, 69)    # Green
MRT_NE = (153, 0, 170)   # Purple
MRT_CC = (255, 161, 0)   # Orange
MRT_DT = (0, 94, 196)    # Blue
MRT_TE = (157, 91, 37)   # Brown
MRT_CG = (0, 150, 69)    # Green

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
    draw.rounded_rectangle(xy, radius=r, fill=fill, outline=outline, width=width)

def round_rect(draw, xy, r, fill, outline=None, width=0):
    draw.rounded_rectangle(xy, radius=r, fill=fill, outline=outline, width=width)

def gen_play_store_screenshot():
    """Generate a Play Store-quality screenshot (1080x1920) showing the unified map with MRT."""
    W, H = 1080, 1920
    img = Image.new("RGB", (W, H), DARK_BG)
    draw = ImageDraw.Draw(img)
    
    # Load fonts
    f_status = load_font(24)
    f_small = load_font(22)
    f_med = load_font(28)
    f_large = load_font(38)
    f_xl = load_font(48)
    f_xxl = load_font(56)

    # ---- Status bar ----
    # Gradient bar at top
    for y in range(0, 56):
        shade = int(40 - y * 0.5)
        draw.line((0, y, W, y), fill=(shade, shade, shade+10))
    draw.text((32, 14), "9:41", fill=WHITE, font=f_status)
    draw.text((240, 14), "▂▄▆█", fill=GREY, font=f_small)
    draw.text((370, 14), "5G", fill=WHITE, font=f_small)
    draw.text((940, 14), "🔋 82%", fill=WHITE, font=f_small)

    # ---- Header ----
    round_rect(draw, (0, 56, W, 130), 0, CARD_BG)
    draw.text((24, 73), "◀", fill=WHITE, font=f_xl)
    draw.text((80, 76), "Map", fill=GOLD, font=f_large)
    # App badge right
    round_rect(draw, (860, 72, 960, 112), 8, (30, 40, 65))
    draw.text((875, 78), "🚌 Nearby", fill=GREEN, font=f_small)
    # Settings gear
    draw.text((1000, 74), "⚙️", fill=WHITE, font=f_xl)

    # ---- Map area ----
    map_top = 130
    map_bot = 870
    
    # Background gradient for map
    for y in range(map_top, map_bot):
        t = (y - map_top) / (map_bot - map_top)
        r = int(20 + t * 10)
        g = int(35 + t * 15)
        b = int(25 + t * 10)
        draw.line((0, y, W, y), fill=(r, g, b))

    # Roads
    road_c = (40, 60, 50)
    for y in range(map_top + 40, map_bot, 35):
        draw.line((0, y, W, y), fill=road_c, width=2)
        draw.line((0, y+1, W, y+1), fill=(road_c[0]+5, road_c[1]+5, road_c[2]+5), width=1)
    for x in range(0, W, 60):
        draw.line((x, map_top, x, map_bot), fill=road_c, width=1)

    # Water body (Marina Bay area)
    # Highlight water
    draw.ellipse((550, 170, 1050, 400), fill=(15, 40, 55))
    draw.ellipse((700, 160, 1050, 380), fill=(12, 35, 50))

    # ---- MRT Station markers ----
    mrt_stations = [
        # (name, line, x, y, color)
        ("Marina Bay", "NS", 360, 290, MRT_NS),
        ("Raffles Place", "EW", 340, 320, MRT_EW),
        ("City Hall", "NS", 300, 275, MRT_NS),
        ("Dhoby Ghaut", "NE", 270, 250, MRT_NE),
        ("Bugis", "EW", 250, 310, MRT_EW),
        ("Tanjong Pagar", "EW", 400, 350, MRT_EW),
        ("Outram Park", "EW", 440, 370, MRT_EW),
        ("Chinatown", "DT", 380, 355, MRT_DT),
        ("Clarke Quay", "NE", 350, 340, MRT_NE),
        ("Little India", "NE", 220, 230, MRT_NE),
        ("HarbourFront", "CC", 480, 430, MRT_CC),
        ("Promenade", "DT", 290, 270, MRT_DT),
        ("Orchard", "NS", 200, 200, MRT_NS),
        ("Somerset", "NS", 230, 220, MRT_NS),
        ("Botanic Gdn", "CC", 160, 180, MRT_CC),
        ("Queenstown", "EW", 520, 400, MRT_EW),
        ("Kallang", "EW", 220, 340, MRT_EW),
        ("Paya Lebar", "EW", 180, 380, MRT_EW),
        ("Bedok", "EW", 100, 440, MRT_EW),
        ("Jurong East", "EW", 700, 390, MRT_EW),
    ]
    
    for name, line, x, y, color in mrt_stations:
        # Shadow
        draw.ellipse((x-14, y-14, x+14, y+14), fill=(0,0,0,80))
        # Circle
        draw.ellipse((x-12, y-12, x+12, y+12), fill=color, outline=WHITE, width=3)
        # Line label
        draw.text((x-6, y-7), line, fill=WHITE, font=load_font(11))

    # ---- Bus stop markers ----
    bus_stops = [
        (420, 310), (310, 350), (280, 290), (450, 330), (330, 300),
        (500, 360), (240, 260), (200, 300), (350, 270), (480, 300),
        (550, 340), (150, 320), (600, 360), (680, 350), (130, 280),
        (170, 350), (640, 320), (720, 330), (190, 190), (110, 340),
    ]
    for sx, sy in bus_stops:
        draw.ellipse((sx-8, sy-8, sx+8, sy+8), fill=TEAL, outline=WHITE, width=2)
        draw.text((sx-5, sy-6), "🚌", fill=WHITE, font=load_font(14))

    # Selected stop (orange, Marina Bay Stn)
    sel_x, sel_y = 360, 290  # Near Marina Bay MRT
    # Pulse ring
    draw.ellipse((sel_x-18, sel_y-18, sel_x+18, sel_y+18), outline=ORANGE, width=3)
    draw.ellipse((sel_x-12, sel_y-12, sel_x+12, sel_y+12), fill=ORANGE, outline=WHITE, width=2)
    draw.text((sel_x-5, sel_y-7), "🚌", fill=WHITE, font=load_font(14))

    # GPS dot
    gx, gy = 520, 320
    for r in [28, 20, 8]:
        draw.ellipse((gx-r, gy-r, gx+r, gy+r), 
                      outline=(BLUE if r > 12 else WHITE), 
                      fill=BLUE if r <= 8 else None, 
                      width=3 if r > 12 else 0)

    # ---- Legend badge ----
    round_rect(draw, (12, 140, 200, 172), 8, CARD_BG)
    draw.ellipse((22, 147, 32, 157), fill=TEAL, outline=WHITE, width=1)
    draw.text((40, 144), "Bus Stop", fill=WHITE, font=load_font(16))
    draw.ellipse((22, 162, 32, 172), fill=MRT_NS, outline=WHITE, width=1)
    draw.text((40, 158), "MRT", fill=WHITE, font=load_font(16))

    # ---- Zoom controls ----
    zx = W - 54
    for i, (label, color) in enumerate([("+", WHITE), ("−", WHITE), ("📍", BLUE)]):
        zy = 520 + i * 54
        round_rect(draw, (zx, zy, zx+42, zy+42), 21, CARD_BG, WHITE, 1)
        draw.text((zx+13, zy+6), label, fill=color, font=f_large)

    # ---- Arrival bottom sheet ----
    sheet_y = 870
    sheet_h = H - sheet_y
    round_rect(draw, (0, sheet_y, W, H), 24, (12, 20, 40))
    
    # Handle
    round_rect(draw, (W//2-25, sheet_y+10, W//2+25, sheet_y+18), 4, SOFT_GREY)

    # Stop header with MRT icon + bus stop
    # Station indicator
    round_rect(draw, (20, sheet_y+30, 110, sheet_y+62), 8, MRT_NS)
    draw.text((28, sheet_y+35), "🚇", fill=WHITE, font=f_small)
    draw.text((56, sheet_y+36), "M.Bay", fill=WHITE, font=load_font(18))
    
    # Bus stop badge
    round_rect(draw, (120, sheet_y+30, 190, sheet_y+62), 8, (30, 45, 80))
    draw.text((128, sheet_y+35), "83121", fill=GOLD, font=f_small)
    
    # Title
    draw.text((200, sheet_y+35), "Marina Bay Stn", fill=WHITE, font=f_small)
    draw.text((1030, sheet_y+35), "✕", fill=GREY, font=f_large)

    # Divider
    draw.line((20, sheet_y+75, W-20, sheet_y+75), fill=(30, 40, 65), width=1)

    # Services
    services = [
        ("97", "SBST", MRT_EW, "Arr", "6m", "15m"),
        ("400", "SMRT", MRT_DT, "2m", "9m", "—"),
        ("133", "SBST", MRT_EW, "5m", "12m", "25m"),
        ("857", "TTS", MRT_CC, "Arr", "8m", "—"),
        ("166", "SBST", MRT_EW, "1m", "7m", "18m"),
    ]
    
    for i, (sno, op, color, t1, t2, t3) in enumerate(services):
        row_y = sheet_y + 86 + i * 44
        
        # Service badge
        round_rect(draw, (20, row_y, 72, row_y+34), 6, (color[0]//3+10, color[1]//3+10, color[2]//3+10))
        draw.text((28, row_y+5), sno, fill=color, font=f_small)
        
        # Operator
        draw.text((80, row_y+8), op, fill=SOFT_GREY, font=load_font(16))
        
        # Arrivals
        col_x = 160
        for time, tc in [(t1, GREEN if t1=="Arr" else ORANGE), 
                         (t2, ORANGE), (t3, SOFT_GREY)]:
            draw.text((col_x, row_y+2), time, fill=tc, font=f_med)
            col_x += 90
        
        # Wheelchair
        if i == 0:
            draw.text((420, row_y+5), "♿", fill=BLUE, font=f_small)
        
        # Route map button
        round_rect(draw, (900, row_y+3, 970, row_y+31), 6, (30, 40, 65))
        draw.text((910, row_y+7), "🗺️", fill=GOLD, font=f_small)
        
        # Divider
        draw.line((20, row_y+40, W-20, row_y+40), fill=(20, 30, 55), width=1)

    # ---- Bottom nav bar ----
    nav_y = H - 80
    round_rect(draw, (0, nav_y, W, H), 0, (8, 14, 28))
    
    nav_items = [
        ("⭐", "Saved", False),
        ("🗺️", "Map", True),
        ("🅿️", "Carpark", False),
        ("🚇", "MRT", False),
        ("⚠️", "Traffic", False),
    ]
    spacing = W / 5
    for i, (icon, label, active) in enumerate(nav_items):
        nx = int(spacing * i + spacing/2)
        col = GOLD if active else GREY
        draw.text((nx-14, nav_y+8), icon, fill=col, font=f_large)
        draw.text((nx-30, nav_y+46), label, fill=col, font=load_font(18))

    # ---- Settings FAB ----
    round_rect(draw, (W-66, H-140, W-14, H-88), 26, CARD_BG, WHITE, 1)
    draw.text((W-50, H-122), "⚙️", fill=WHITE, font=f_large)

    # ---- Nearby badge (collapsed) ----
    round_rect(draw, (12, sheet_y-40, 340, sheet_y-6), 10, CARD_BG)
    draw.text((24, sheet_y-32), "📍", fill=BLUE, font=load_font(20))
    draw.text((52, sheet_y-32), "15 nearby stops · Nearest: 80m", fill=GREEN, font=load_font(18))
    draw.text((310, sheet_y-32), "✕", fill=GREY, font=load_font(18))

    # Save
    path = f"{OUT}/screenshot_1.png"
    img.save(path)
    print(f"Screenshot saved: {path} ({os.path.getsize(path)//1024}KB)")

def gen_feature_graphic():
    """Generate 1024x500 Play Store feature graphic."""
    W, H = 1024, 500
    img = Image.new("RGB", (W, H), DARK_BG)
    draw = ImageDraw.Draw(img)

    # Gradient background
    for y in range(H):
        t = y / H
        r = 10 + int(t * 5)
        g = 18 + int(t * 10)
        b = 35 + int(t * 8)
        draw.line((0, y, W, y), fill=(r, g, b))

    # Subtle grid
    for x in range(0, W, 40):
        draw.line((x, 0, x, H), fill=(20, 30, 50), width=1)
    for y in range(0, H, 40):
        draw.line((0, y, W, y), fill=(20, 30, 50), width=1)

    # Left side: Branding
    f_title = load_font(52)
    f_sub = load_font(32)
    f_tag = load_font(20)
    f_feat = load_font(18)

    # Badges
    round_rect(draw, (40, 30, 180, 62), 12, MRT_NS)
    draw.text((55, 36), "🚇 Singapore Transport", fill=WHITE, font=load_font(16))
    
    round_rect(draw, (190, 30, 280, 62), 12, (30, 45, 80))
    draw.text((202, 36), "🇨🇳 中文支持", fill=WHITE, font=load_font(16))

    # Title
    draw.text((40, 90), "Nāvisg", fill=GOLD, font=f_title)
    draw.text((40, 150), "Navigate Singapore", fill=WHITE, font=f_sub)

    # Tagline
    draw.text((40, 210), "Real-time bus · MRT · Carpark · Traffic · Live Map", fill=GREY, font=f_tag)

    # Feature pills
    features = ["⏱️ Auto-refresh", "🌙 Dark Mode", "🇨🇳 中文", "📱 QR Share", "📍 GPS Map"]
    x = 40
    for feat in features:
        round_rect(draw, (x, 260, x+140, 290), 14, CARD_BG)
        draw.text((x+10, 265), feat, fill=WHITE, font=f_feat)
        x += 148

    # Right side: Phone mockup
    phone_x, phone_y = W - 340, 60
    phone_w, phone_h = 280, 380
    # Phone body
    round_rect(draw, (phone_x, phone_y, phone_x+phone_w, phone_y+phone_h), 28, (20, 30, 50), GREY, 2)
    # Screen
    round_rect(draw, (phone_x+12, phone_y+18, phone_x+phone_w-12, phone_y+phone_h-18), 20, DARK_BG)
    
    # Mini map on screen
    screen_x, screen_y = phone_x+20, phone_y+28
    screen_w, screen_h = phone_w-40, phone_h-56
    
    # Map grid
    for y in range(screen_y, screen_y+screen_h, 15):
        draw.line((screen_x, y, screen_x+screen_w, y), fill=(20, 40, 30), width=1)
    for x in range(screen_x, screen_x+screen_w, 20):
        draw.line((x, screen_y, x, screen_y+screen_h), fill=(20, 40, 30), width=1)
    
    # Mini bus stops
    for _ in range(6):
        import random
        px = screen_x + random.randint(10, screen_w-10)
        py = screen_y + random.randint(10, screen_h-10)
        draw.ellipse((px-3, py-3, px+3, py+3), fill=TEAL)

    # MRT dots (colored circles)
    mrt_dots = [(screen_x+80, screen_y+40, MRT_NS), 
                (screen_x+100, screen_y+70, MRT_EW),
                (screen_x+70, screen_y+100, MRT_DT)]
    for mx, my, mc in mrt_dots:
        draw.ellipse((mx-4, my-4, mx+4, my+4), fill=mc, outline=WHITE, width=1)

    # Bottom arrival sheet mini
    sheet_my = screen_y + screen_h - 60
    draw.rounded_rectangle((screen_x+5, sheet_my, screen_x+screen_w-5, screen_y+screen_h-5), 
                            radius=8, fill=(15, 25, 45))
    draw.text((screen_x+15, sheet_my+8), "🚌 83121 Marina Bay", fill=GOLD, font=load_font(10))
    draw.text((screen_x+15, sheet_my+25), "97 Arr  400 2m  166 1m", fill=WHITE, font=load_font(9))

    # Bottom nav on phone
    draw.text((screen_x+20, screen_y+screen_h-18), "⭐ 🗺️ 🅿️ 🚇 ⚠️", fill=GREY, font=load_font(10))

    # Save
    path = f"{OUT}/feature_graphic.png"
    img.save(path)
    print(f"Feature graphic saved: {path} ({os.path.getsize(path)//1024}KB)")

def gen_keyword_banner():
    """Generate 1024x240 keyword banner for Play Store."""
    W, H = 1024, 240
    img = Image.new("RGB", (W, H), DARK_BG)
    draw = ImageDraw.Draw(img)

    # Gradient
    for y in range(H):
        t = y / H
        r = 10 + int(t * 5)
        g = 18 + int(t * 8)
        b = 35 + int(t * 5)
        draw.line((0, y, W, y), fill=(r, g, b))

    f_lg = load_font(40)
    f_md = load_font(26)
    f_sm = load_font(16)

    # Brand
    draw.text((40, 20), "Nāvisg", fill=GOLD, font=f_lg)
    draw.text((40, 65), "Singapore Transport — Bus 🚌 MRT 🚇 Carpark 🅿️ Traffic ⚠️ Map 🗺️", 
              fill=GREY, font=f_sm)

    # Feature badges
    badges = ["⏱️ Auto-refresh", "🌙 Dark Mode", "🇨🇳 中文", "🔄 Reorder", "📱 QR Share", "📍 GPS Map"]
    x = 40
    y = 120
    for badge in badges:
        draw.rounded_rectangle((x, y, x+130, y+30), radius=15, fill=CARD_BG)
        draw.text((x+8, y+5), badge, fill=WHITE, font=load_font(15))
        x += 138

    # App store badges
    round_rect(draw, (40, 170, 160, 200), 8, (0, 50, 100))
    draw.text((52, 175), "▶ Google Play", fill=WHITE, font=load_font(16))
    round_rect(draw, (170, 170, 290, 200), 8, (30, 45, 80))
    draw.text((182, 175), "🍎 App Store", fill=WHITE, font=load_font(16))

    path = f"{OUT}/keyword_banner.png"
    img.save(path)
    print(f"Keyword banner saved: {path} ({os.path.getsize(path)//1024}KB)")

if __name__ == "__main__":
    gen_play_store_screenshot()
    gen_feature_graphic()
    gen_keyword_banner()
    print("\nAll graphics generated!")
