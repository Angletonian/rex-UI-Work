"""Settlement-label icons for the SSHIP / M2EX HD UI.

White glyphs on transparent, with a soft dark outline. The label script multiplies them by its
tint (public order colour, growth colour, queue green), so white becomes the tint and the outline
stays dark, which keeps them readable against the plate and the map.

Drawn at 512px and reduced to 64px (the label draws them at roughly 18-27px).
"""
import math
from PIL import Image, ImageDraw, ImageFilter

S = 512            # working size
OUT = 64           # delivered size
WHITE = 255
OUTLINE_PX = 22    # at 512 -> ~2.75px at 64
OUTLINE_ALPHA = 210


def canvas():
    return Image.new("L", (S, S), 0)


def rot(pts, deg, cx=S / 2, cy=S / 2):
    a = math.radians(deg)
    c, s = math.cos(a), math.sin(a)
    return [(cx + (x - cx) * c - (y - cy) * s, cy + (x - cx) * s + (y - cy) * c) for x, y in pts]


def rect_pts(x0, y0, x1, y1):
    return [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]


# ---------------------------------------------------------------- glyphs (white mask, L mode)

def shield():
    """Public order: a heater shield with a cut inner border."""
    m = canvas()
    d = ImageDraw.Draw(m)

    def shape(inset):
        top, right = 70 + inset, S - 92 - inset
        shoulder = top + 150
        tip_y = S - 58 - inset * 1.3
        # right flank: straight to the shoulder, then a quadratic curve into the point
        right_side = [(S / 2, top), (right, top), (right, shoulder)]
        p0, p1, p2 = (right, shoulder), (right, shoulder + (tip_y - shoulder) * 0.55), (S / 2, tip_y)
        for i in range(1, 25):
            t = i / 24
            x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t ** 2 * p2[0]
            y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t ** 2 * p2[1]
            right_side.append((x, y))
        left_side = [(S - x, y) for x, y in reversed(right_side[1:-1])]
        return right_side + left_side

    d.polygon(shape(0), fill=WHITE)
    d.line(shape(34) + [shape(34)[0]], fill=0, width=18, joint="curve")
    # a pale in the middle, so it reads as a shield even at 20px
    d.rectangle([S / 2 - 16, 120, S / 2 + 16, S - 150], fill=0)
    return m


def person(d, cx, top, scale=1.0):
    r = 50 * scale
    d.ellipse([cx - r, top, cx + r, top + 2 * r], fill=WHITE)
    bw, bh = 92 * scale, 150 * scale
    by = top + 2 * r + 12 * scale
    d.rounded_rectangle([cx - bw, by, cx + bw, by + bh], radius=int(70 * scale), fill=WHITE)


def people(m):
    """Two figures, the front one cut clear of the back one."""
    person(ImageDraw.Draw(m), 150, 92, 0.9)
    front = canvas()
    person(ImageDraw.Draw(front), 225, 150, 1.0)
    m.paste(0, (0, 0), front.filter(ImageFilter.MaxFilter(23)))
    m.paste(WHITE, (0, 0), front)


def growth(kind):
    m = canvas()
    people(m)
    d = ImageDraw.Draw(m)
    ax, shaft = 405, 30
    if kind == "rising":
        d.polygon([(ax, 70), (ax + 88, 195), (ax - 88, 195)], fill=WHITE)
        d.rectangle([ax - shaft, 190, ax + shaft, 330], fill=WHITE)
    elif kind == "falling":
        d.rectangle([ax - shaft, 150, ax + shaft, 300], fill=WHITE)
        d.polygon([(ax, 430), (ax + 88, 295), (ax - 88, 295)], fill=WHITE)
    else:  # stable
        d.rounded_rectangle([ax - 80, 215, ax + 80, 265], radius=14, fill=WHITE)
        d.rounded_rectangle([ax - 80, 300, ax + 80, 350], radius=14, fill=WHITE)
    return m


def construction():
    """Crossed hammer and mason's trowel."""
    m = canvas()
    # hammer, drawn upright then turned
    h = canvas()
    hd = ImageDraw.Draw(h)
    hd.rounded_rectangle([S / 2 - 24, 150, S / 2 + 24, 470], radius=20, fill=WHITE)      # handle
    hd.rounded_rectangle([S / 2 - 120, 70, S / 2 + 95, 165], radius=18, fill=WHITE)       # head
    hd.polygon([(S / 2 + 90, 80), (S / 2 + 150, 100), (S / 2 + 150, 135), (S / 2 + 90, 155)],
               fill=WHITE)                                                                  # face
    h = h.rotate(-40, resample=Image.BICUBIC, center=(S / 2, S / 2))
    # trowel
    t = canvas()
    td = ImageDraw.Draw(t)
    td.polygon([(S / 2, 60), (S / 2 + 95, 270), (S / 2 - 95, 270)], fill=WHITE)          # blade
    td.rectangle([S / 2 - 14, 265, S / 2 + 14, 330], fill=WHITE)                          # tang
    td.rounded_rectangle([S / 2 - 30, 325, S / 2 + 30, 470], radius=26, fill=WHITE)      # grip
    t = t.rotate(40, resample=Image.BICUBIC, center=(S / 2, S / 2))
    # the hammer sits on top: cut a gap around it through the trowel
    gap = h.filter(ImageFilter.MaxFilter(25))
    m.paste(WHITE, (0, 0), t)
    m.paste(0, (0, 0), gap)
    m.paste(WHITE, (0, 0), h)
    return m


def recruitment():
    """Crossed swords."""
    def sword():
        s = canvas()
        d = ImageDraw.Draw(s)
        cx = S / 2
        d.polygon([(cx, 40), (cx + 30, 100), (cx + 30, 330), (cx - 30, 330), (cx - 30, 100)], fill=WHITE)
        d.rounded_rectangle([cx - 100, 325, cx + 100, 365], radius=16, fill=WHITE)   # guard
        d.rectangle([cx - 18, 360, cx + 18, 440], fill=WHITE)                       # grip
        d.ellipse([cx - 34, 430, cx + 34, 490], fill=WHITE)                         # pommel
        return s
    a = sword().rotate(-42, resample=Image.BICUBIC, center=(S / 2, S / 2))
    b = sword().rotate(42, resample=Image.BICUBIC, center=(S / 2, S / 2))
    m = canvas()
    m.paste(WHITE, (0, 0), b)
    m.paste(0, (0, 0), a.filter(ImageFilter.MaxFilter(23)))
    m.paste(WHITE, (0, 0), a)
    return m


def automanaged():
    """A cog: the settlement runs itself."""
    m = canvas()
    d = ImageDraw.Draw(m)
    cx = cy = S / 2
    teeth, r_out, r_in = 8, 215, 165
    pts = []
    for i in range(teeth * 2):
        a0 = (i / (teeth * 2)) * 2 * math.pi
        a1 = ((i + 1) / (teeth * 2)) * 2 * math.pi
        r = r_out if i % 2 == 0 else r_in
        # flatten each tooth: two points per half-step, tooth sides slightly tapered
        taper = 0.10 if i % 2 == 0 else -0.02
        pts.append((cx + r * math.cos(a0 + taper), cy + r * math.sin(a0 + taper)))
        pts.append((cx + r * math.cos(a1 - taper), cy + r * math.sin(a1 - taper)))
    d.polygon(pts, fill=WHITE)
    d.ellipse([cx - 72, cy - 72, cx + 72, cy + 72], fill=0)
    return m


def siege():
    """A crenellated tower with a scaling ladder thrown against it."""
    m = canvas()
    d = ImageDraw.Draw(m)
    x0, x1, top, base = 120, 330, 130, 460
    d.rectangle([x0, top, x1, base], fill=WHITE)
    mw = (x1 - x0) / 5
    for i in (0, 2, 4):                                  # merlons
        d.rectangle([x0 + i * mw, top - 70, x0 + (i + 1) * mw, top + 2], fill=WHITE)
    d.rounded_rectangle([x0 + 2 * mw + 8, 210, x0 + 3 * mw - 8, 300], radius=16, fill=0)   # arrow slit
    d.pieslice([x0 + 55, 360, x1 - 55, 520], 180, 360, fill=0)                              # gate
    # ladder, drawn upright then leaned against the tower's right wall
    lad = canvas()
    ld = ImageDraw.Draw(lad)
    lx, lw = 370, 88
    ld.rectangle([lx - lw / 2 - 16, 40, lx - lw / 2 + 16, 490], fill=WHITE)
    ld.rectangle([lx + lw / 2 - 16, 40, lx + lw / 2 + 16, 490], fill=WHITE)
    for y in range(90, 480, 72):
        ld.rectangle([lx - lw / 2, y, lx + lw / 2, y + 22], fill=WHITE)
    lad = lad.rotate(-16, resample=Image.BICUBIC, center=(lx, 470))
    m.paste(0, (0, 0), lad.filter(ImageFilter.MaxFilter(23)))
    m.paste(WHITE, (0, 0), lad)
    return m


def unrest():
    """A burning torch."""
    m = canvas()
    d = ImageDraw.Draw(m)
    cx = S / 2

    def flame(scale, dy=0):
        pts = []
        for i in range(0, 61):
            t = i / 60 * 2 * math.pi
            # teardrop: round base, drawn up to a point (screen y runs down, so sin < 0 is the top)
            up = (1 + math.sin(t)) / 2          # 0 at the top, 1 at the bottom
            r = 0.06 + 0.94 * up ** 0.55
            x = math.cos(t) * 118 * r * scale
            y = math.sin(t) * 150 * scale
            if math.sin(t) < 0:
                y *= 1.3
                x += 22 * scale * math.sin(t) ** 2   # the tip leans a little, as a flame does
            pts.append((cx + x, 250 + dy + y))
        return pts

    d.polygon(flame(1.0), fill=WHITE)
    d.polygon(flame(0.48, 36), fill=0)                                 # hot core cut out
    d.polygon([(cx - 70, 380), (cx + 70, 380), (cx + 34, 490), (cx - 34, 490)], fill=WHITE)   # handle
    d.rectangle([cx - 88, 356, cx + 88, 392], fill=WHITE)             # collar
    d.rectangle([cx - 100, 340, cx + 100, 356], fill=0)               # gap between flame and collar
    return m


def plague():
    """A skull."""
    m = canvas()
    d = ImageDraw.Draw(m)
    cx = S / 2
    d.ellipse([cx - 175, 60, cx + 175, 370], fill=WHITE)                   # cranium
    d.rounded_rectangle([cx - 110, 300, cx + 110, 455], radius=30, fill=WHITE)   # jaw
    d.ellipse([cx - 130, 190, cx - 30, 290], fill=0)                      # eyes
    d.ellipse([cx + 30, 190, cx + 130, 290], fill=0)
    d.polygon([(cx, 300), (cx - 30, 355), (cx + 30, 355)], fill=0)        # nose
    for x in (-60, 0, 60):                                                # teeth gaps
        d.rectangle([cx + x - 9, 395, cx + x + 9, 455], fill=0)
    d.rectangle([cx - 110, 385, cx + 110, 400], fill=0)                  # mouth line
    return m


def races():
    """A horseshoe, heels down."""
    m = canvas()
    d = ImageDraw.Draw(m)
    cx, cy = S / 2, 230
    ro, ri = 185, 105
    d.ellipse([cx - ro, cy - ro, cx + ro, cy + ro], fill=WHITE)
    d.ellipse([cx - ri, cy - ri, cx + ri, cy + ri], fill=0)
    d.rectangle([cx - ro, cy, cx + ro, S], fill=0)
    # the arms run straight down to the heels
    d.rectangle([cx - ro, cy - 1, cx - ri, 440], fill=WHITE)
    d.rectangle([cx + ri, cy - 1, cx + ro, 440], fill=WHITE)
    d.rounded_rectangle([cx - ro - 14, 410, cx - ri + 6, 460], radius=12, fill=WHITE)   # heels
    d.rounded_rectangle([cx + ri - 6, 410, cx + ro + 14, 460], radius=12, fill=WHITE)
    rm = (ro + ri) / 2                                                   # nail holes
    for deg in (200, 240, 300, 340):
        a = math.radians(deg)
        hx, hy = cx + rm * math.cos(a), cy + rm * math.sin(a)
        d.ellipse([hx - 15, hy - 15, hx + 15, hy + 15], fill=0)
    for y in (300, 370):
        for x in (cx - rm, cx + rm):
            d.ellipse([x - 15, y - 15, x + 15, y + 15], fill=0)
    return m


def games():
    """A laurel wreath, open at the top."""
    m = canvas()
    cx, cy, r = S / 2, 275, 175
    for side in (-1, 1):
        for i in range(7):
            # from the bottom (90 deg) round to near the top, on each side
            deg = 90 + side * (22 + i * 21)
            a = math.radians(deg)
            lx, ly = cx + r * math.cos(a), cy + r * math.sin(a)
            leaf = Image.new("L", (S, S), 0)
            ImageDraw.Draw(leaf).ellipse([S / 2 - 30, S / 2 - 62, S / 2 + 30, S / 2 + 62], fill=WHITE)
            # lie along the ring, tipped outward
            leaf = leaf.rotate(-(deg + 90) + side * 14, resample=Image.BICUBIC)
            m.paste(WHITE, (int(lx - S / 2), int(ly - S / 2)), leaf)
    d = ImageDraw.Draw(m)
    d.arc([cx - r, cy - r, cx + r, cy + r], 90 + 20, 90 + 155, fill=WHITE, width=16)   # stems
    d.arc([cx - r, cy - r, cx + r, cy + r], 90 - 155, 90 - 20, fill=WHITE, width=16)
    d.ellipse([cx - 30, cy + r - 30, cx + 30, cy + r + 30], fill=WHITE)             # tie
    return m


# ---------------------------------------------------------------- finishing

def finish(mask):
    """White fill over a soft dark outline, reduced to OUT px, as RGBA."""
    outline = mask.filter(ImageFilter.MaxFilter(OUTLINE_PX * 2 + 1)).filter(ImageFilter.GaussianBlur(4))
    outline = outline.point(lambda v: min(255, v * OUTLINE_ALPHA // 255))
    rgba = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    rgba.paste((0, 0, 0, 255), (0, 0), outline)
    rgba.paste((255, 255, 255, 255), (0, 0), mask)
    return rgba.resize((OUT, OUT), Image.LANCZOS)


ICONS = {
    "loyalty":         shield,
    "growth_rising":   lambda: growth("rising"),
    "growth_stable":   lambda: growth("stable"),
    "growth_falling":  lambda: growth("falling"),
    "construction":    construction,
    "recruitment":     recruitment,
    "automanaged":     automanaged,
    "siege":           siege,
    "unrest":          unrest,
    "plague":          plague,
    "races":           races,
    "games":           games,
}

if __name__ == "__main__":
    import os
    os.makedirs("icons", exist_ok=True)
    for name, fn in ICONS.items():
        finish(fn()).save(f"icons/{name}.png")
        print("wrote icons/" + name + ".png")
