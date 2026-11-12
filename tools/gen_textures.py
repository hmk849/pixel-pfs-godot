#!/usr/bin/env python3
"""Pixpfs texture generator - pixel-art assets generated procedurally."""
import os, random
from PIL import Image, ImageDraw, ImageFilter
import numpy as np

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures")
os.makedirs(OUT, exist_ok=True)
random.seed(20260113)

def save(img, name):
    img.save(os.path.join(OUT, name))
    print("wrote", name)

def noise_rgb(w, h, base, var, seed=None):
    rng = np.random.default_rng(seed if seed is not None else random.randrange(1 << 30))
    n = rng.integers(-var, var + 1, size=(h, w, 1), dtype=np.int16)
    arr = np.clip(np.array(base, dtype=np.int16) + n, 0, 255).astype(np.uint8)
    return Image.fromarray(arr, "RGB")

def tex_concrete(w=256, h=256, tint=(96, 96, 102)):
    img = noise_rgb(w, h, tint, 10)
    d = ImageDraw.Draw(img)
    rng = np.random.default_rng(7)
    for _ in range(60):  # cracks & stains
        x, y = rng.integers(0, w), rng.integers(0, h)
        r = rng.integers(2, 10)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(int(tint[0] * 0.82), int(tint[1] * 0.82), int(tint[2] * 0.82)))
    for _ in range(8):  # seams
        y0 = int(rng.integers(0, h))
        d.line([(0, y0), (w, y0)], fill=(int(tint[0] * 0.7), int(tint[1] * 0.7), int(tint[2] * 0.7)), width=2)
    return img

def tex_metal(w=256, h=256, base=(70, 76, 86), ridged=True):
    img = noise_rgb(w, h, base, 8)
    d = ImageDraw.Draw(img)
    if ridged:
        for x in range(0, w, 32):
            d.rectangle([x, 0, x + 5, h], fill=(base[0] + 14, base[1] + 14, base[2] + 16))
            d.rectangle([x + 5, 0, x + 9, h], fill=(max(base[0] - 16, 0), max(base[1] - 16, 0), max(base[2] - 14, 0)))
    for _ in range(14):  # scratches
        x, y = random.randint(0, w), random.randint(0, h)
        d.line([(x, y), (x + random.randint(-30, 30), y + random.randint(-8, 8))], fill=(140, 145, 155), width=1)
    return img

def tex_rust_container(w=256, h=256, base=(140, 84, 52)):
    img = noise_rgb(w, h, base, 14)
    d = ImageDraw.Draw(img)
    for x in range(0, w, 64):  # corrugation
        d.rectangle([x, 0, x + 10, h], fill=(min(base[0] + 26, 255), min(base[1] + 18, 255), min(base[2] + 10, 255)))
        d.rectangle([x + 40, 0, x + 52, h], fill=(max(base[0] - 24, 0), max(base[1] - 18, 0), max(base[2] - 10, 0)))
    rng = np.random.default_rng(3)
    for _ in range(50):  # rust blooms
        x, y = rng.integers(0, w), rng.integers(0, h)
        r = rng.integers(3, 14)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(120, 58, 30))
    return img

def tex_crate(w=128, h=128):
    img = noise_rgb(w, h, (124, 92, 56), 10)
    d = ImageDraw.Draw(img)
    for y in range(0, h, 16):  # planks
        d.line([(0, y), (w, y)], fill=(84, 60, 34), width=2)
    d.rectangle([2, 2, w - 3, h - 3], outline=(70, 50, 28), width=4)  # frame
    d.line([(4, 4), (w - 5, h - 5)], fill=(96, 68, 40), width=3)
    d.line([(w - 5, 4), (4, h - 5)], fill=(96, 68, 40), width=3)
    return img

def tex_neon_panel(w=128, h=128, glow=(0, 230, 240)):
    img = Image.new("RGB", (w, h), (16, 14, 28))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, w - 1, h - 1], outline=glow, width=3)
    d.rectangle([10, 10, w - 11, h - 11], outline=(glow[0] // 3, glow[1] // 3, glow[2] // 3), width=2)
    for y in range(20, h - 12, 24):
        d.line([(14, y), (w - 15, y)], fill=glow, width=2)
    return img

def tex_grid_floor(w=256, h=256, base=(24, 26, 34), line=(58, 64, 84)):
    img = noise_rgb(w, h, base, 4)
    d = ImageDraw.Draw(img)
    step = 64
    for x in range(0, w, step):
        d.line([(x, 0), (x, h)], fill=line, width=2)
    for y in range(0, h, step):
        d.line([(0, y), (w, y)], fill=line, width=2)
    d.line([(0, 0), (2, 2)], fill=(90, 200, 255))
    return img

def tex_target(w=128, h=128):
    img = Image.new("RGB", (w, h), (235, 232, 225))
    d = ImageDraw.Draw(img)
    cx = w // 2
    rings = [(0, 255, 60, 60), (0, 245, 245, 245), (255, 70, 70, 70)]
    d.ellipse([4, 4, w - 5, h - 5], outline=(40, 40, 44), width=4)
    d.ellipse([14, 14, w - 15, h - 15], fill=rings[0])
    d.ellipse([34, 34, w - 35, h - 35], fill=rings[1])
    d.ellipse([52, 52, w - 53, h - 53], fill=rings[0])
    d.ellipse([cx - 6, cx - 6, cx + 6, cx + 6], fill=(20, 20, 24))
    return img

def tex_hazard(w=128, h=128):
    img = Image.new("RGB", (w, h), (28, 28, 32))
    d = ImageDraw.Draw(img)
    s = 16
    for i in range(-h // s, w // s + 1):
        d.polygon([(i * s, 0), (i * s + s, 0), (i * s + s + h, h), (i * s + h, h)], fill=(230, 180, 40))
    return img

def tex_muzzle(w=64, h=64):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = w // 2, h // 2
    d.ellipse([cx - 26, cy - 26, cx + 26, cy + 26], fill=(255, 210, 120, 230))
    d.ellipse([cx - 16, cy - 16, cx + 16, cy + 16], fill=(255, 250, 220, 255))
    d.polygon([(cx, cy - 30), (cx + 6, cy), (cx, cy + 30), (cx - 6, cy)], fill=(255, 230, 150, 255))
    d.polygon([(cx - 30, cy), (cx, cy - 6), (cx + 30, cy), (cx, cy + 6)], fill=(255, 230, 150, 255))
    return img

def camo(palette, w=64, h=64):
    img = Image.new("RGB", (w, h), palette[0])
    d = ImageDraw.Draw(img)
    for col in palette[1:]:
        for _ in range(26):
            x, y = random.randint(-8, w), random.randint(-8, h)
            r = random.randint(4, 12)
            for dx, dy in [(0, 0), (r, 0), (-r, 0)]:
                d.ellipse([x - r + dx, y - r + dy // 2, x + r + dx, y + r + dy // 2], fill=col)
    return img

def face(w=32, h=32, visor=(30, 220, 240)):
    img = Image.new("RGB", (w, h), (34, 34, 40))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, w - 1, 5], fill=(20, 20, 24))          # helmet top
    d.rectangle([3, 9, 13, 13], fill=visor)                    # goggles L
    d.rectangle([18, 9, 28, 13], fill=visor)                   # goggles R
    d.rectangle([10, 19, 21, 27], fill=(52, 52, 60))           # mask
    for i in range(3):
        d.line([(11 + i * 3, 20), (11 + i * 3, 26)], fill=(24, 24, 28))
    return img

# ---------- 3x5 pixel font for logo ----------
FONT = {
    "P": ["111", "101", "111", "100", "100"],
    "I": ["111", "010", "010", "010", "111"],
    "X": ["101", "101", "010", "101", "101"],
    "F": ["111", "100", "110", "100", "100"],
    "S": ["111", "100", "111", "001", "111"],
    "0": ["111", "101", "101", "101", "111"],
    "4": ["101", "101", "111", "001", "001"],
    " ": ["00", "00", "00", "00", "00"],
}
def pixel_text(text, px=10, fg=(240, 244, 250), bg=None, glow=None):
    width = sum((3 if c != " " else 2) + 1 for c in text) - 1
    W, H = width * px + px * 2, 7 * px + px * 2
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    x = px
    for ch in text:
        glyph = FONT.get(ch, FONT["0"])
        for gy, row in enumerate(glyph):
            for gx, c in enumerate(row):
                if c == "1":
                    d.rectangle([x + gx * px, px + gy * px, x + (gx + 1) * px - 1, px + (gy + 1) * px - 1], fill=fg)
        x += (3 if ch != " " else 2) * px + px
    if glow:
        big = Image.new("RGBA", img.size, (0, 0, 0, 0))
        big.paste(glow, (8, 8), img.split()[3])
        big = big.filter(ImageFilter.GaussianBlur(4))
        return Image.alpha_composite(big, img)
    return img

# ---------- icon: pixel special forces soldier ----------
def make_icon():
    S = 8  # cell size
    W = H = 16
    img = Image.new("RGB", (W * S, H * S), (26, 24, 34))
    d = ImageDraw.Draw(img)
    def cell(x, y, col):
        d.rectangle([x * S, y * S, (x + 1) * S - 1, (y + 1) * S - 1], fill=col)
    # radial glow bg
    for r in range(14, 0, -1):
        a = int(40 * (r / 14))
        d.ellipse([8 * S - r * S, 8 * S - r * S, 8 * S + r * S, 8 * S + r * S], fill=(26 + a, 24 + a, 34 + a))
    body = (46, 66, 52)
    dark = (32, 46, 38)
    vest = (58, 58, 62)
    skin = (200, 160, 120)
    # helmet + face
    for x in range(5, 11):
        cell(x, 1, dark); cell(x, 2, body)
    cell(5, 3, body); cell(10, 3, body)
    cell(6, 3, skin); cell(7, 3, (30, 30, 34)); cell(8, 3, (30, 30, 34)); cell(9, 3, skin)
    for x in range(5, 11):
        cell(x, 4, body)
    # torso with vest
    for y in range(5, 9):
        for x in range(5, 11):
            cell(x, y, body if x in (5, 10) else vest)
    cell(6, 6, (200, 70, 60)); cell(9, 6, (200, 70, 60))   # red accents
    # arms
    for y in range(5, 8):
        cell(4, y, body); cell(11, y, body)
    # legs
    for y in range(9, 13):
        cell(6, y, dark); cell(9, y, dark)
        cell(5, y, body); cell(10, y, body)
    # boots
    cell(6, 13, (20, 20, 22)); cell(9, 13, (20, 20, 22))
    # rifle held across
    gun = (28, 28, 32); gun2 = (52, 52, 58)
    for x in range(2, 14):
        cell(x, 7, gun)
    cell(13, 7, gun2); cell(4, 7, gun2)   # barrel + stock
    cell(9, 6, (90, 90, 96))              # sight
    return img.resize((128, 128), Image.NEAREST)

def portrait(palette, visor, seed):
    """96x96 operator portrait, pixel style bust."""
    rng = random.Random(seed)
    img = Image.new("RGB", (96, 96), (18, 18, 24))
    d = ImageDraw.Draw(img)
    # backdrop
    for y in range(96):
        t = y / 95
        d.line([(0, y), (95, y)], fill=(int(30 + t * 26), int(20 + t * 18), int(36 + t * 26)))
    base, c1, c2 = palette
    def rect(x, y, w, h, col):
        d.rectangle([x, y, x + w - 1, y + h - 1], fill=col)
    # helmet
    rect(24, 12, 48, 22, c1)
    rect(26, 30, 44, 4, c2)
    # face shadow
    rect(30, 34, 36, 12, (25, 25, 30))
    # visor strip
    rect(30, 36, 36, 8, visor)
    rect(32, 46, 32, 3, (50, 50, 58))  # breather
    # shoulders/vest
    rect(12, 56, 72, 40, c1)
    rect(20, 60, 56, 30, c2)
    rect(38, 64, 20, 18, (40, 40, 46))  # chest plate
    # accents
    for i in range(4):
        rect(24 + i * 14, 90, 6, 4, visor)
    # scanlines
    for y in range(0, 96, 3):
        d.line([(0, y), (95, y)], fill=(0, 0, 0))
    return img

def map_thumb_rust():
    img = Image.new("RGB", (256, 144), (30, 26, 30))
    d = ImageDraw.Draw(img)
    for y in range(144):  # floor gradient
        t = y / 143
        d.line([(0, y), (255, y)], fill=(int(66 + t * 30), int(48 + t * 20), int(38 + t * 16)))
    rng = random.Random(5)
    for _ in range(9):  # containers
        x, y = rng.randint(6, 200), rng.randint(60, 118)
        w, h = rng.randint(28, 52), rng.randint(16, 26)
        col = rng.choice([(150, 88, 50), (96, 104, 118), (120, 70, 60)])
        d.rectangle([x, y, x + w, y + h], fill=col, outline=(30, 24, 22))
    d.rectangle([100, 28, 156, 58], fill=(74, 66, 60), outline=(40, 34, 30))  # crane
    d.text((18, 12), "RUST DEPOT", fill=(240, 200, 140))
    return img

def map_thumb_neon():
    img = Image.new("RGB", (256, 144), (12, 10, 30))
    d = ImageDraw.Draw(img)
    for y in range(144):
        t = y / 143
        d.line([(0, y), (255, y)], fill=(int(16 + t * 20), int(12 + t * 10), int(40 + t * 30)))
    # skyline
    rng = random.Random(9)
    x = 0
    while x < 256:
        w = rng.randint(14, 34)
        h = rng.randint(24, 66)
        d.rectangle([x, 60 - h, x + w, 70], fill=(20, 16, 44))
        for _ in range(5):
            d.point((x + rng.randint(2, w - 3), 60 - rng.randint(4, h - 6)), fill=(90, 200, 255))
        x += w + 3
    # rooftop
    d.rectangle([0, 70, 255, 144], fill=(24, 20, 40))
    for i in range(6):  # AC units
        d.rectangle([16 + i * 40, 86 + (i % 2) * 18, 44 + i * 40, 100 + (i % 2) * 18], fill=(36, 32, 56), outline=(0, 210, 220))
    d.rectangle([10, 128, 246, 132], fill=(255, 60, 160))
    d.text((18, 12), "NEON ROOFTOP", fill=(0, 230, 240))
    return img

def ui_icon_crate():
    img = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([6, 12, 41, 41], fill=(124, 92, 56, 255), outline=(70, 50, 28, 255), width=3)
    for y in (20, 28, 36):
        d.line([(6, y), (41, y)], fill=(84, 60, 34, 255), width=2)
    d.line([(6, 12), (41, 41)], fill=(96, 68, 40, 255), width=3)
    return img

def ui_icon_helmet():
    img = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([10, 10, 37, 30], 6, fill=(52, 62, 54, 255))
    d.rectangle([14, 18, 33, 23], fill=(30, 220, 240, 255))
    d.rectangle([16, 30, 31, 38], fill=(52, 58, 60, 255))
    for i in range(3):
        d.line([(19 + i * 4, 31), (19 + i * 4, 37)], fill=(24, 24, 28, 255))
    return img

def ui_icon_target():
    img = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = 24
    d.ellipse([4, 4, 43, 43], fill=(235, 232, 225, 255))
    d.ellipse([9, 9, 38, 38], fill=(255, 60, 60, 255))
    d.ellipse([15, 15, 32, 32], fill=(245, 245, 245, 255))
    d.ellipse([20, 20, 27, 27], fill=(255, 60, 60, 255))
    d.ellipse([cx - 2, cx - 2, cx + 2, cx + 2], fill=(20, 20, 24, 255))
    return img

if __name__ == "__main__":
    save(make_icon(), "icon.png")
    save(ui_icon_crate(), "ui_crate.png")
    save(ui_icon_helmet(), "ui_helmet.png")
    save(ui_icon_target(), "ui_target.png")
    save(tex_concrete(), "concrete.png")
    save(tex_concrete(256, 256, (70, 78, 88)), "concrete_dark.png")
    save(tex_metal(), "metal.png")
    save(tex_metal(256, 256, (58, 62, 74)), "metal_dark.png")
    save(tex_rust_container(), "container.png")
    save(tex_crate(), "crate.png")
    save(tex_neon_panel(), "neon_cyan.png")
    save(tex_neon_panel(128, 128, (255, 60, 160)), "neon_pink.png")
    save(tex_grid_floor(), "grid_floor.png")
    save(tex_target(), "target.png")
    save(tex_hazard(), "hazard.png")
    save(tex_muzzle(), "muzzle_flash.png")
    for x in range(4):
        save(tex_grid_floor(256, 256, (24 + x * 4, 26, 34), (58 + x * 10, 64, 84)), f"floor_{x}.png")
    save(pixel_text("PIXPFS", 12, (240, 244, 250), glow=(255, 70, 85, 160)), "logo.png")
    save(pixel_text("PIXEL FORGE", 6, (150, 155, 170), glow=(80, 120, 255, 90)), "studio.png")
    ops = {
        "ghost": [((40, 52, 44), (26, 34, 30), (58, 74, 62)), (30, 220, 240)],
        "viper": [((36, 52, 40), (22, 34, 26), (70, 120, 60)), (120, 255, 80)],
        "owl":   [((36, 42, 60), (24, 28, 40), (56, 66, 92)), (200, 120, 255)],
        "bear":  [((70, 56, 40), (50, 40, 28), (96, 78, 56)), (255, 170, 40)],
        "kestrel": [((60, 34, 36), (44, 24, 26), (130, 46, 50)), (255, 90, 100)],
    }
    for i, (op, (pal, visor)) in enumerate(ops.items()):
        save(camo(list(pal)), f"camo_{op}.png")
        save(face(32, 32, visor), f"face_{op}.png")
        save(portrait(pal, visor, 100 + i), f"portrait_{op}.png")
    save(map_thumb_rust(), "thumb_rust.png")
    save(map_thumb_neon(), "thumb_neon.png")
    save(noise_rgb(32, 32, (48, 50, 58), 10), "gun_metal.png")
    print("ALL TEXTURES DONE")
