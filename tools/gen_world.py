"""Tileset, sfondi parallax, illustrazioni delle cutscene, UI e icone."""
import math
from pixel import Canvas, gradient, rng, col, lerp, LCD_BG, LCD_FG
import gen_sprites as spr
from font_nokia import text_canvas

T = 16


# ---------------------------------------------------------------- tileset
def noise_fill(cv, x0, y0, w, h, base, dots, seed, density=0.18):
    r = rng(seed)
    cv.rect(x0, y0, w, h, base)
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            if r.random() < density:
                cv.set(x, y, r.choice(dots))


def tiles_esterno(cv, oy):
    # 0 terra con erba
    noise_fill(cv, 0, oy, T, T, "n", ["N", "Y"], 1)
    cv.rect(0, oy, T, 5, "g")
    for x in range(0, T, 3):
        cv.set(x, oy + 5, "g"); cv.set(x + 1, oy + 5, "G")
    for x in range(1, T, 4):
        cv.set(x, oy, "t")
    cv.line(0, oy + 4, 15, oy + 4, "G")
    # 1 terra
    noise_fill(cv, T, oy, T, T, "n", ["N", "Y"], 2)
    cv.circle(T + 5, oy + 9, 1.5, "a")
    # 2 piattaforma tronco
    cv.rect(2 * T, oy, T, 6, "n")
    cv.line(2 * T, oy, 3 * T - 1, oy, "Y")
    cv.line(2 * T, oy + 5, 3 * T - 1, oy + 5, "N")
    cv.set(2 * T + 4, oy + 2, "N"); cv.set(2 * T + 11, oy + 3, "N")
    # 3 melma radioattiva
    noise_fill(cv, 3 * T, oy + 6, T, 10, "G", ["t"], 3, 0.3)
    for x in range(T):
        cv.set(3 * T + x, oy + 5 + int(math.sin(x * 0.8) * 1.2), "t")
        cv.set(3 * T + x, oy + 6 + int(math.sin(x * 0.8) * 1.2), "t")
    # 4 fiori viola
    for fx, fy, c in ((4, 9, "v"), (11, 7, "p"), (8, 12, "y")):
        cv.line(4 * T + fx, oy + fy + 1, 4 * T + fx, oy + 15, "G")
        cv.circle(4 * T + fx, oy + fy, 1.6, c)
        cv.set(4 * T + fx, oy + fy, "y" if c != "y" else "w")
    # 5 ciuffo d'erba
    for gx in range(2, 14, 2):
        cv.line(5 * T + gx, oy + 15, 5 * T + gx + (1 if gx % 4 else -1), oy + 9 + gx % 3, "g")
    # 6 sasso
    cv.ellipse(6 * T + 8, oy + 12, 6, 4, "a"); cv.ellipse(6 * T + 7, oy + 11, 3, 2, "W")
    # 7 osso
    cv.line(7 * T + 3, oy + 13, 7 * T + 12, oy + 11, "w")
    for ex, ey in ((3, 13), (12, 11)):
        cv.circle(7 * T + ex, oy + ey - 1, 1, "w"); cv.circle(7 * T + ex, oy + ey + 1, 1, "w")


def tiles_bunker(cv, oy):
    # 0 pavimento metallico
    noise_fill(cv, 0, oy, T, T, "A", ["a"], 11, 0.08)
    cv.rect(0, oy, T, 4, "a")
    cv.line(0, oy, 15, oy, "W")
    cv.set(2, oy + 2, "W"); cv.set(13, oy + 2, "W")
    # 1 cemento
    noise_fill(cv, T, oy, T, T, "A", ["a", (56, 52, 58)], 12, 0.15)
    cv.line(T, oy + 15, 2 * T - 1, oy + 15, (56, 52, 58))
    # 2 grata
    cv.rect(2 * T, oy, T, 5, "a")
    for x in range(0, T, 3):
        cv.rect(2 * T + x, oy + 1, 1, 3, "k")
    cv.line(2 * T, oy, 3 * T - 1, oy, "W")
    # 3 vetri rotti
    for x in range(0, T, 4):
        cv.poly([(3 * T + x, oy + 16), (3 * T + x + 2, oy + 6 + (x % 3)), (3 * T + x + 4, oy + 16)], "c")
        cv.line(3 * T + x + 2, oy + 7 + (x % 3), 3 * T + x + 2, oy + 15, "w")
    # 4 bottiglie vuote
    for bx, c in ((3, "G"), (8, "n"), (12, "G")):
        cv.rect(4 * T + bx, oy + 9, 3, 7, c); cv.rect(4 * T + bx + 1, oy + 6, 1, 3, c)
    # 5 cassa
    cv.rect(5 * T + 2, oy + 4, 12, 12, "n"); cv.line(5 * T + 2, oy + 4, 5 * T + 13, oy + 15, "N")
    cv.line(5 * T + 13, oy + 4, 5 * T + 2, oy + 15, "N")
    # 6 barile radioattivo
    cv.rect(6 * T + 3, oy + 2, 10, 14, "y"); cv.line(6 * T + 3, oy + 6, 6 * T + 12, oy + 6, "Y")
    cv.line(6 * T + 3, oy + 12, 6 * T + 12, oy + 12, "Y"); cv.circle(6 * T + 8, oy + 9, 2, "k")
    # 7 lampada lava rosa
    cv.rect(7 * T + 6, oy + 12, 4, 4, "a"); cv.ellipse(7 * T + 8, oy + 8, 3, 5, "p")
    cv.circle(7 * T + 8, oy + 7, 1, "w")


def tiles_nucleare(cv, oy):
    # 0 terreno bruciato
    noise_fill(cv, 0, oy, T, T, "N", ["A", "n"], 21, 0.25)
    cv.rect(0, oy, T, 3, "A")
    for x in range(1, T, 5):
        cv.line(x, oy + 3, x + 1, oy + 7, "t")
    cv.line(0, oy, 15, oy, "a")
    # 1 sottosuolo
    noise_fill(cv, T, oy, T, T, (50, 34, 28), ["N", "A"], 22, 0.2)
    # 2 trave arrugginita
    cv.rect(2 * T, oy, T, 5, "o"); cv.line(2 * T, oy + 4, 3 * T - 1, oy + 4, "n")
    for x in range(1, T, 5):
        cv.set(2 * T + x, oy + 2, "N")
    # 3 melma tossica
    noise_fill(cv, 3 * T, oy + 5, T, 11, "t", ["y", "g"], 23, 0.3)
    for x in range(0, T, 5):
        cv.circle(3 * T + x + 2, oy + 5, 1.5, "t")
    # 4 teschio
    cv.circle(4 * T + 8, oy + 10, 4, "w"); cv.rect(4 * T + 6, oy + 13, 5, 3, "w")
    cv.set(4 * T + 6, oy + 10, "k"); cv.set(4 * T + 10, oy + 10, "k"); cv.set(4 * T + 8, oy + 12, "k")
    # 5 ceppo morto
    cv.rect(5 * T + 6, oy + 6, 4, 10, "N"); cv.line(5 * T + 7, oy + 6, 5 * T + 3, oy + 1, "N")
    cv.line(5 * T + 9, oy + 7, 5 * T + 13, oy + 3, "N")
    # 6 fiore mutato
    cv.line(6 * T + 8, oy + 15, 6 * T + 8, oy + 7, "G")
    cv.circle(6 * T + 8, oy + 6, 3, "t"); cv.circle(6 * T + 8, oy + 6, 1, "k")
    # 7 macerie
    cv.poly([(7 * T + 1, oy + 16), (7 * T + 5, oy + 9), (7 * T + 10, oy + 12), (7 * T + 15, oy + 16)], "a")
    cv.line(7 * T + 5, oy + 9, 7 * T + 8, oy + 15, "A")


def build_tiles(path):
    cv = Canvas(8 * T, 3 * T)
    tiles_esterno(cv, 0)
    tiles_bunker(cv, T)
    tiles_nucleare(cv, 2 * T)
    cv.save(path)


# ---------------------------------------------------------------- sfondi
W, H = 320, 180


def mountains(cv, base_y, amp, color, seed, step=8):
    r = rng(seed)
    pts, x, y = [], -10, base_y
    while x < cv.w + 20:
        pts.append((x, y))
        x += r.randint(step, step * 3)
        y = base_y - r.randint(0, amp)
    pts += [(cv.w + 20, cv.h), (-10, cv.h)]
    cv.poly(pts, color)


def mushroom_cloud(cv, cx, base, s=1.0, cols=("t", "g", "G")):
    cv.rect(cx - 5 * s, base - 50 * s, 10 * s, 50 * s, cols[1])
    cv.rect(cx - 3 * s, base - 50 * s, 3 * s, 50 * s, cols[0])
    for (ox, oy, r, c) in ((-20, -55, 14, 1), (20, -55, 14, 1), (0, -62, 18, 0), (-12, -66, 12, 0),
                          (12, -66, 12, 0), (0, -48, 10, 2), (-26, -48, 8, 2), (26, -48, 8, 2)):
        cv.circle(cx + ox * s, base + oy * s, r * s, cols[c])
    cv.ellipse(cx, base - 30 * s, 16 * s, 4 * s, cols[2])
    cv.ellipse(cx, base, 34 * s, 6 * s, cols[1])


def ruins(cv, base, color, seed, holes=None, max_h=90):
    r = rng(seed)
    x = 0
    while x < cv.w:
        w, h = r.randint(18, 40), r.randint(max_h // 3, max_h)
        cv.rect(x, base - h, w, h, color)
        for _ in range(r.randint(1, 3)):  # bordo spezzato
            bx = x + r.randint(0, w - 6)
            cv.rect(bx, base - h, r.randint(3, 8), r.randint(3, 12), (0, 0, 0, 0))
        if holes:
            for wy in range(base - h + 8, base - 6, 10):
                for wx in range(x + 4, x + w - 4, 8):
                    if r.random() < 0.6:
                        cv.rect(wx, wy, 3, 4, holes)
        x += w + r.randint(4, 30)


def dead_tree(cv, x, base, h, c):
    cv.rect(x, base - h, 3, h, c)
    cv.line(x + 1, base - h * 0.6, x - 8, base - h * 0.9, c)
    cv.line(x + 1, base - h * 0.4, x + 10, base - h * 0.75, c)
    cv.line(x + 1, base - h, x - 3, base - h - 8, c)


def build_backgrounds(d):
    # --- esterno
    far = Canvas(W, H)
    gradient(far, (90, 150, 220), (230, 210, 170), 0, H, 10)
    far.circle(250, 40, 14, (255, 236, 160)); far.circle(250, 40, 11, (255, 250, 220))
    mountains(far, 110, 50, (120, 110, 150), 5, 10)
    mountains(far, 135, 30, (90, 120, 110), 6, 8)
    far.save(f"{d}/esterno_far.png")
    near = Canvas(W, H)
    mountains(near, 150, 18, (70, 140, 70), 7, 6)
    r = rng(8)
    for x in range(0, W, 30):
        tx = x + r.randint(0, 14)
        near.rect(tx + 3, 120, 3, 35, (90, 60, 40))
        near.circle(tx + 4, 116, 10, (60, 120, 60)); near.circle(tx, 120, 7, (50, 105, 55))
    for _ in range(60):
        fx, fy = r.randint(0, W), r.randint(150, 178)
        near.set(fx, fy, r.choice(["v", "p", "y", "w"]))
    near.save(f"{d}/esterno_near.png")

    # --- bunker
    far = Canvas(W, H)
    gradient(far, (60, 54, 66), (36, 30, 40), 0, H, 6)
    for x in range(0, W, 40):
        far.rect(x, 0, 2, H, (30, 26, 34))
    for y in (30, 100):
        far.rect(0, y, W, 4, (90, 84, 92)); far.rect(0, y + 4, W, 1, (20, 16, 24))
    for x in (20, 180):  # poster radioattivi
        far.rect(x, 50, 26, 34, (230, 200, 70)); far.circle(x + 13, 65, 7, "k")
        far.circle(x + 13, 65, 2, (230, 200, 70))
    for x in (100, 260):  # luci da discoteca
        far.circle(x, 14, 6, (220, 90, 170)); far.circle(x, 14, 3, (255, 200, 230))
    far.save(f"{d}/bunker_far.png")
    near = Canvas(W, H)
    for x in (10, 170):  # casse
        near.rect(x, 110, 22, 50, (30, 26, 30)); near.circle(x + 11, 125, 7, (80, 80, 90))
        near.circle(x + 11, 125, 3, "k"); near.circle(x + 11, 146, 5, (80, 80, 90))
    for x in (60, 230):  # divani rosa
        near.rect(x, 140, 50, 20, (220, 90, 170)); near.rect(x, 128, 50, 14, (190, 70, 150))
        near.rect(x - 4, 132, 6, 28, (170, 60, 140)); near.rect(x + 48, 132, 6, 28, (170, 60, 140))
    for x in (130, 290):  # scaffali con bottiglie
        near.rect(x, 80, 26, 3, (100, 70, 50)); near.rect(x, 100, 26, 3, (100, 70, 50))
        for bx in range(x + 2, x + 24, 5):
            near.rect(bx, 72, 3, 8, "G"); near.rect(bx, 92, 3, 8, "n")
    near.save(f"{d}/bunker_near.png")

    # --- zona nucleare
    far = Canvas(W, H)
    gradient(far, (60, 90, 40), (190, 200, 90), 0, H, 10)
    mushroom_cloud(far, 160, 140, 1.0, ((200, 250, 120), (150, 210, 80), (110, 160, 60)))
    mountains(far, 140, 25, (70, 80, 50), 31, 10)
    far.save(f"{d}/nucleare_far.png")
    near = Canvas(W, H)
    ruins(near, 170, (40, 46, 40), 32, holes=(150, 200, 80))
    for x in (40, 150, 270):
        dead_tree(near, x, 172, 40, (30, 26, 22))
    near.rect(0, 168, W, 12, (40, 32, 28))
    near.save(f"{d}/nucleare_near.png")


# ---------------------------------------------------------------- cutscene
CW, CH = 192, 108


def big(sprite, s):
    return sprite.scaled(s)


def scene_humans():
    cv = Canvas(CW, CH)
    gradient(cv, (200, 170, 130), (120, 90, 60), 0, CH, 6)
    r = rng(41)
    for i, x in enumerate(range(-6, CW, 34)):
        kind = "donna" if i % 2 else "uomo"
        h = spr.human(kind, 0, "up" if i % 3 == 0 else "fist").scaled(3)
        h.tint(lambda c: lerp(c, (110, 80, 50, 255), 0.55))
        cv.blit(h, x, 10 + r.randint(-6, 6))
    lb = spr.ladybug(0, hand=(16, 18))
    lb.tint(lambda c: (30, 20, 20, 255))
    cv.blit(big(lb, 2), 70, 60)
    return cv


def scene_hate():
    cv = Canvas(CW, CH)
    gradient(cv, (120, 10, 20), (30, 0, 10), 0, CH, 8)
    for a in range(0, 360, 20):
        ang = math.radians(a)
        cv.line(96, 54, 96 + math.cos(ang) * 120, 54 + math.sin(ang) * 120, (90, 0, 15))
    cv.blit(big(spr.ladybug(0, hand=(20, 10), eyes="crazy", motion=True), 4), 48, 8)
    return cv


def scene_bomb():
    cv = Canvas(CW, CH)
    gradient(cv, (40, 40, 50), (20, 20, 26), 0, CH, 5)
    cv.rect(0, 88, CW, 20, (60, 50, 40))
    cv.ellipse(120, 62, 34, 22, (80, 90, 80)); cv.ellipse(120, 58, 30, 16, (110, 120, 110))
    cv.poly([(150, 50), (176, 38), (176, 86), (150, 74)], (80, 90, 80))
    cv.circle(120, 60, 11, "y")
    for a in range(3):
        ang = a * 2 * math.pi / 3 - math.pi / 2
        for rr in range(3, 10):
            for d in (-0.4, 0, 0.4):
                cv.set(120 + math.cos(ang + d) * rr, 60 + math.sin(ang + d) * rr, "k")
    cv.blit(big(spr.ladybug(0, hand=(22, 14), eyes="crazy"), 2), 20, 40)
    for x, y in ((70, 30), (90, 20), (60, 18)):
        cv.set(x, y, "y"); cv.set(x + 1, y, "w")
    return cv


def scene_women():
    cv = Canvas(CW, CH)
    gradient(cv, (250, 190, 210), (200, 120, 170), 0, CH, 8)
    for i, x in enumerate(range(8, CW, 30)):
        cv.blit(spr.human("donna", i, "up" if i % 2 else "down").scaled(2), x, 40 + (i % 2) * 4)
    cv.blit(big(spr.ladybug(0, hand=(20, 8)), 2), 76, 58)
    return cv


def scene_bunker_door():
    cv = Canvas(CW, CH)
    gradient(cv, (230, 150, 90), (120, 60, 70), 0, CH, 8)
    cv.rect(0, 84, CW, 24, (70, 120, 60))
    cv.blit(spr.door(True).scaled(2), 120, 22)
    for i in range(4):
        h = spr.human("donna", i, "up").scaled(2)
        cv.blit(h, 30 + i * 22, 38)
    return cv


def scene_explosion():
    cv = Canvas(CW, CH)
    gradient(cv, (60, 10, 10), (250, 150, 40), 0, CH, 10)
    mushroom_cloud(cv, 96, 104, 1.35, ((255, 240, 160), (250, 160, 40), (200, 70, 20)))
    ruins(cv, 108, (40, 16, 16), 50, max_h=34)
    return cv


def scene_harem():
    cv = Canvas(CW, CH)
    gradient(cv, (60, 20, 60), (140, 40, 110), 0, CH, 8)
    for x, c in ((30, (255, 120, 200)), (96, (120, 200, 255)), (160, (255, 230, 120))):
        cv.poly([(x, 0), (x - 26, CH), (x + 26, CH)], lerp(col(c), (140, 40, 110, 255), 0.6))
    cv.rect(40, 80, 112, 28, (220, 90, 170))
    for i, x in enumerate((4, 30, 140, 166)):
        cv.blit(spr.human("donna", i, "up" if i % 2 else "down").scaled(2), x, 44)
    cv.blit(big(spr.ladybug(0, hand=(20, 8), eyes="half"), 3), 60, 30)
    return cv


def scene_crack():
    cv = Canvas(CW, CH)
    gradient(cv, (70, 64, 72), (40, 36, 44), 0, CH, 5)
    for y in range(0, CH, 12):
        for x in range((y // 12 % 2) * 12, CW, 24):
            cv.rect(x, y, 23, 11, (80, 74, 82))
    cv.blit(spr.crack(True).scaled(2), 100, 4)
    cv.blit(big(spr.ladybug(0, hand=(20, 14), lean=2, eyes="x"), 2), 52, 56)
    for x, y in ((78, 50), (94, 46), (70, 44)):
        cv.pattern(x, y, ["#.#", ".#.", "#.#"], {"#": "y"})
    return cv


def scene_alone():
    cv = Canvas(CW, CH)
    gradient(cv, (80, 120, 50), (190, 210, 110), 0, CH, 8)
    mushroom_cloud(cv, 140, 90, 0.9, ((200, 250, 120), (150, 210, 80), (110, 160, 60)))
    ruins(cv, 92, (60, 70, 50), 60, max_h=36)
    cv.rect(0, 90, CW, 18, (60, 110, 40))
    for x in range(0, CW, 7):
        cv.set(x, 90, "t")
    cv.blit(big(spr.ladybug(0, hand=(16, 18), eyes="half"), 2), 40, 58)
    return cv


def scene_sheep():
    cv = Canvas(CW, CH)
    gradient(cv, (250, 120, 60), (120, 40, 90), 0, 80, 10)
    cv.circle(96, 76, 22, (255, 200, 90))
    cv.rect(0, 80, CW, 28, (40, 20, 30))
    sh = spr.sheep(0).scaled(3)
    sh.tint(lambda c: (25, 12, 20, 255))
    cv.blit(sh, 70, 38)
    lb = spr.ladybug(0, hand=(20, 8), eyes="crazy")
    lb.tint(lambda c: (25, 12, 20, 255))
    cv.blit(lb, 20, 58)
    cv.pattern(26, 46, [".#.#.", "#####", ".###.", "..#.."], {"#": "p"})
    return cv


def scene_title():
    cv = Canvas(CW, CH, LCD_BG)
    logo = text_canvas("ROSANF?", LCD_FG, 3)
    cv.blit(logo, (CW - logo.w) // 2, 20)
    cv.blit(spr.ladybug(0, hand=(16, 18)), 84, 64)
    return cv


SCENES = {
    "umani": scene_humans, "odio": scene_hate, "bomba": scene_bomb, "donne": scene_women,
    "porta_bunker": scene_bunker_door, "esplosione": scene_explosion, "harem": scene_harem,
    "crepa": scene_crack, "sola": scene_alone, "pecora": scene_sheep, "titolo": scene_title,
}


def build_cutscenes(d):
    for name, fn in SCENES.items():
        fn().save(f"{d}/{name}.png")


# ---------------------------------------------------------------- UI
def heart(full=True):
    cv = Canvas(9, 8)
    cv.pattern(0, 0, [".##.##...", "#######..", "#######..", ".#####...", "..###....", "...#....."],
               {"#": "r" if full else "A"})
    if full:
        cv.set(1, 1, "l")
    cv.outline("k")
    return cv


def touch_button(kind):
    cv = Canvas(32, 32)
    cv.circle(15.5, 15.5, 14, (255, 255, 255, 70))
    cv.circle(15.5, 15.5, 12, (255, 255, 255, 40))
    fg = (255, 255, 255, 200)
    if kind == "left":
        cv.poly([(9, 16), (20, 8), (20, 24)], fg)
    elif kind == "right":
        cv.poly([(23, 16), (12, 8), (12, 24)], fg)
    elif kind == "pause":
        cv.rect(11, 9, 4, 14, fg); cv.rect(18, 9, 4, 14, fg)
    else:
        t = text_canvas(kind.upper(), fg, 2)
        cv.blit(t, 16 - t.w // 2, 16 - 11)
    return cv


def chapter_icon(i):
    cv = Canvas(16, 16)
    if i == 1:
        cv.circle(8, 8, 7, "w"); cv.circle(8, 8, 5, None)
        for a in range(3):
            ang = a * 2 * math.pi / 3 - math.pi / 2
            for rr in range(2, 6):
                for d in (-0.4, 0, 0.4):
                    cv.set(8 + math.cos(ang + d) * rr, 8 + math.sin(ang + d) * rr, "w")
        cv.circle(8, 8, 1, "w")
    elif i == 2:
        cv.rect(6, 1, 4, 4, "w"); cv.rect(4, 5, 8, 10, "w"); cv.rect(6, 8, 4, 3, None)
    else:
        cv.circle(8, 5, 5, "w"); cv.rect(6, 9, 4, 6, "w"); cv.rect(3, 14, 10, 2, "w")
        cv.circle(6, 4, 1, None); cv.circle(10, 6, 1, None)
    return cv


def lcd_icon(kind):
    cv = Canvas(8, 8)
    pats = {
        "lock": ["..##....", ".#..#...", ".#..#...", "######..", "##..##..", "######..", "######.."],
        "ladybug": ["..#.#...", "..###...", ".#####..", "##.#.##.", "#######.", ".#####..", "..#.#..."],
        "uranio": ["..##....", ".####...", "##..##..", "#.##.#..", "##..##..", ".####...", "..##...."],
    }
    cv.pattern(0, 0, pats[kind], {"#": "w"})
    return cv


def build_ui(d, root):
    heart(True).save(f"{d}/cuore.png")
    heart(False).save(f"{d}/cuore_vuoto.png")
    for k in ("left", "right", "a", "b", "pause"):
        touch_button(k).save(f"{d}/touch_{k}.png")
    for i in (1, 2, 3):
        chapter_icon(i).save(f"{d}/capitolo_{i}.png")
    for k in ("lock", "ladybug", "uranio"):
        lcd_icon(k).save(f"{d}/icona_{k}.png")
    # logo testuale
    logo = text_canvas("ROSANF?", "w", 4)
    lg = Canvas(logo.w + 8, logo.h + 8)
    lg.blit(logo, 4, 4)
    lg.save(f"{d}/logo.png")
    # mascotte per il menu (coccinella in LCD monocromatica)
    lb = spr.ladybug(0, hand=(16, 18)).scaled(2)
    lb.tint(lambda c: LCD_FG if sum(c[:3]) < 400 else LCD_BG)
    lb.save(f"{d}/menu_coccinella.png")
    dead = spr.shift(spr.vflip(spr.ladybug(0, ((-2, 0), (2, 0)), hand=(18, 18), eyes="x")), 0, 2).scaled(2)
    dead.tint(lambda c: LCD_FG if sum(c[:3]) < 400 else LCD_BG)
    dead.save(f"{d}/menu_morta.png")
    # icona app
    ic = Canvas(128, 128, LCD_BG)
    ic.rect(0, 0, 128, 6, LCD_FG); ic.rect(0, 122, 128, 6, LCD_FG)
    ic.rect(0, 0, 6, 128, LCD_FG); ic.rect(122, 0, 6, 128, LCD_FG)
    ic.blit(spr.ladybug(0, hand=(16, 18)).scaled(4), 16, 10)
    t = text_canvas("ROSANF?", LCD_FG, 2)
    ic.blit(t, (128 - t.w) // 2, 100)
    ic.save(f"{root}/icon.png")
