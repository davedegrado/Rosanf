"""Sprite: coccinella, nemici, NPC, oggetti. Ogni sheet ha un .json con le animazioni."""
import json
import math
from pixel import Canvas, sheet


# ---------------------------------------------------------------- coccinella
def ladybug(bob=0, legs=((0, 0), (0, 0)), hand=None, lean=0, eyes="open",
            prop=None, sit=False, hearts=(), smoke=0, motion=False):
    cv = Canvas(24, 24)
    sx, sy = 10 + lean * 0.5, 15 + bob
    hx, hy = 15 + lean, 9 + bob

    # zampe (dietro al guscio)
    if sit:
        cv.line(sx - 1, sy + 4, sx + 3, sy + 6, "K")
        cv.line(sx + 3, sy + 4, sx + 7, sy + 6, "K")
    else:
        for i, (dx, lift) in enumerate(legs):
            hipx = sx - 2 + i * 4
            fx, fy = hipx + dx, 22 - lift
            cv.line(hipx, sy + 3, fx, fy, "K")
            cv.set(fx + 1, fy, "K")

    # guscio
    cv.ellipse(sx, sy, 6, 5, "r")
    for y in range(24):
        for x in range(24):
            if cv.get(x, y) == (214, 48, 49, 255) and y > sy + 2.5:
                cv.set(x, y, "R")
    for ox, oy, r in ((-3, -1, 1.3), (1, 1, 1.4), (-2, 3, 1.0), (3, -3, 1.1), (-5, 1, 0.8)):
        cv.circle(sx + ox, sy + oy, r, "K")
    cv.set(sx - 2, sy - 4, "l")
    cv.set(sx - 1, sy - 4, "l")
    cv.set(sx - 3, sy - 3, "l")

    # antenne
    cv.line(hx - 1, hy - 3, hx - 3, hy - 7, "K")
    cv.line(hx + 2, hy - 3, hx + 3, hy - 7, "K")
    cv.set(hx - 3, hy - 8, "K")
    cv.set(hx + 3, hy - 8, "K")

    # testa
    cv.circle(hx, hy, 4.2, "K")
    if eyes == "x":
        for ex in (hx, hx + 3):
            cv.set(ex - 1, hy - 2, "w"); cv.set(ex + 1, hy - 2, "w")
            cv.set(ex, hy - 1, "w")
            cv.set(ex - 1, hy, "w"); cv.set(ex + 1, hy, "w")
    else:
        for ex in (hx, hx + 3):
            cv.ellipse(ex, hy - 1, 1.6, 1.9 if eyes == "open" else 0.8, "w")
            cv.set(ex + 1, hy - 1 + (0 if eyes == "open" else 0), "k")
            if eyes == "crazy":
                cv.set(ex, hy - 2, "k")
        # ghigno demente
        cv.line(hx, hy + 2, hx + 3, hy + 2, "w")
        cv.set(hx + 4, hy + 1, "w")

    # braccio
    if hand:
        shx, shy = sx + 4, sy - 1
        cv.line(shx, shy, hand[0], hand[1] + bob, "K")
        cv.set(hand[0] + 1, hand[1] + bob, "K")

    # oggetti di scena
    if prop == "bottle" and hand:
        bx, by = hand[0], hand[1] + bob
        cv.rect(bx, by - 4, 3, 4, "G")
        cv.rect(bx + 1, by - 6, 1, 2, "G")
        cv.set(bx, by - 3, "g")
    if prop == "joint" and hand:
        cv.line(hand[0], hand[1] + bob, hand[0] + 3, hand[1] + bob - 1, "w")
        cv.set(hand[0] + 3, hand[1] + bob - 1, "o")
    if smoke:
        for i in range(smoke):
            cv.circle(hx + 4 + i, hy - 6 - i * 2, 1.5 + i * 0.4, "W")
    if prop == "broom":
        cv.line(1, 21, 23, 19, "n")
        cv.line(1, 22, 23, 20, "N")
        for k in range(5):
            cv.line(0, 19 + k, -4 + 5, 20 + k * 0.3, "Y")
        cv.rect(0, 19, 3, 5, "Y")
        cv.set(3, 21, "o")
    if motion:
        cv.line(21, hy + 3, 23, hy + 3, "w")
        cv.line(20, hy + 6, 23, hy + 6, "w")

    cv.outline("k")
    for (px, py) in hearts:  # i cuoricini fluttuano senza contorno pesante
        cv.pattern(px, py, [".#.#.", "#####", ".###.", "..#.."], {"#": "p"})
    return cv


def vflip(cv):
    out = Canvas(cv.w, cv.h)
    for y in range(cv.h):
        out.px[y] = cv.px[cv.h - 1 - y][:]
    return out


def shift(cv, dx, dy):
    out = Canvas(cv.w, cv.h)
    out.blit(cv, dx, dy)
    return out


def build_ladybug(path):
    anims = {}
    frames = []

    def add(name, fs, fps, loop=True):
        anims[name] = {"start": len(frames), "count": len(fs), "fps": fps, "loop": loop}
        frames.extend(fs)

    add("idle", [ladybug(0, hand=(16, 18)), ladybug(1, hand=(16, 18))], 3)
    add("walk", [
        ladybug(0, ((-2, 0), (2, 0)), hand=(17, 17)),
        ladybug(1, ((0, 1), (0, 0)), hand=(16, 18)),
        ladybug(0, ((2, 0), (-2, 0)), hand=(15, 18)),
        ladybug(1, ((0, 0), (0, 1)), hand=(16, 18)),
    ], 8)
    add("run", [
        ladybug(0, ((-3, 1), (3, 0)), hand=(19, 13), lean=1),
        ladybug(1, ((0, 2), (1, 0)), hand=(18, 15), lean=1),
        ladybug(0, ((3, 0), (-3, 1)), hand=(13, 16), lean=1),
        ladybug(1, ((1, 0), (0, 2)), hand=(16, 15), lean=1),
    ], 12)
    add("jump", [ladybug(-1, ((-1, 2), (1, 2)), hand=(19, 8))], 1)
    add("fall", [ladybug(0, ((-2, 0), (2, 0)), hand=(19, 10), eyes="crazy")], 1)
    add("attack", [
        ladybug(0, ((-2, 0), (2, 0)), hand=(12, 15)),
        ladybug(0, ((-3, 0), (3, 0)), hand=(22, 13), lean=2, motion=True, eyes="crazy"),
        ladybug(0, ((-2, 0), (2, 0)), hand=(20, 14), lean=1),
    ], 14, False)
    add("broom", [
        ladybug(-2, hand=(21, 16), sit=True, prop="broom", hearts=[(1, 0), (17, 2)]),
        ladybug(-3, hand=(21, 16), sit=True, prop="broom", hearts=[(2, 1), (18, 0)]),
    ], 8)
    add("drink", [
        ladybug(0, hand=(18, 10), prop="bottle"),
        ladybug(0, hand=(17, 8), prop="bottle", eyes="half"),
    ], 4)
    add("drug", [
        ladybug(0, hand=(18, 11), prop="joint", smoke=2, eyes="half"),
        ladybug(1, hand=(18, 12), prop="joint", smoke=3, eyes="crazy"),
    ], 4)
    add("hurt", [ladybug(0, ((-1, 0), (1, 0)), hand=(19, 6), lean=-2, eyes="x")], 1)
    dead = shift(vflip(ladybug(0, ((-2, 0), (2, 0)), hand=(18, 18), eyes="x")), 0, 2)
    add("dead", [dead], 1, False)

    sheet(frames, path + ".png")
    with open(path + ".json", "w") as f:
        json.dump({"frame_w": 24, "frame_h": 24, "anims": anims}, f, indent=1)
    return frames


# ---------------------------------------------------------------- umani
def human(kind="uomo", step=0, arms="down", hurt=False, bob=0):
    cv = Canvas(16, 24)
    skin, skin2 = ("s", "S") if kind != "mutante" else ("t", "G")
    shirt = {"uomo": "b", "mutante": "G", "donna": "p"}[kind]
    y = bob
    # gambe
    l1, l2 = [(0, 0), (-2, 2), (0, 0), (2, -2)][step % 4]
    leg = "B" if kind != "donna" else skin
    cv.line(7, 17 + y, 6 + l1, 23, leg)
    cv.line(9, 17 + y, 10 + l2, 23, leg)
    cv.set(6 + l1 + 1, 23, "k" if kind != "donna" else "P")
    cv.set(10 + l2 + 1, 23, "k" if kind != "donna" else "P")
    if kind == "donna":
        cv.ellipse(8, 7 + y, 4, 5, "y")       # capelli lunghi dietro
        cv.rect(4, 7 + y, 8, 6, "y")
        cv.poly([(5, 10 + y), (11, 10 + y), (13, 19 + y), (3, 19 + y)], shirt)  # vestito
    else:
        cv.rect(5, 9 + y, 7, 8, shirt)
        cv.rect(5, 15 + y, 7, 3, "B" if kind == "uomo" else "N")
        if kind == "mutante":
            cv.set(6, 13 + y, "t"); cv.set(10, 11 + y, "t")
    # braccia
    if arms == "up":
        cv.line(5, 10 + y, 3, 5 + y, skin)
        cv.line(11, 10 + y, 13, 5 + y, skin)
    elif arms == "fist":
        cv.line(11, 10 + y, 14, 11 + y, skin)
        cv.line(5, 10 + y, 4, 15 + y, skin)
    else:
        cv.line(5, 10 + y, 4, 15 + y, skin)
        cv.line(11, 10 + y, 12, 15 + y, skin)
    # testa
    cv.circle(8, 5 + y, 3.4, skin)
    cv.set(6, 7 + y, skin2)
    if kind == "uomo":
        cv.rect(5, 1 + y, 7, 2, "N"); cv.set(5, 3 + y, "N")
    elif kind == "mutante":
        cv.set(7, 1 + y, "t"); cv.set(9, 2 + y, "t")
    else:
        cv.rect(5, 1 + y, 7, 2, "y")
    if hurt:
        cv.set(9, 4 + y, "k"); cv.set(10, 5 + y, "k"); cv.set(11, 4 + y, "k")
    else:
        eye = "y" if kind == "mutante" else "k"
        cv.set(10, 5 + y, eye)
        if kind != "donna":
            cv.line(9, 3 + y, 11, 4 + y, "k")  # sopracciglio arrabbiato
            cv.line(9, 7 + y, 10, 7 + y, "R")
        else:
            cv.set(10, 7 + y, "r")
    cv.outline("k")
    return cv


def build_human(kind, path):
    anims, frames = {}, []

    def add(name, fs, fps, loop=True):
        anims[name] = {"start": len(frames), "count": len(fs), "fps": fps, "loop": loop}
        frames.extend(fs)

    if kind == "donna":
        add("idle", [human(kind, 0), human(kind, 0, bob=1)], 3)
        add("dance", [human(kind, 1, "up"), human(kind, 3, "down", bob=1),
                      human(kind, 3, "up"), human(kind, 1, "down", bob=1)], 6)
        add("happy", [human(kind, 0, "up"), human(kind, 0, "up", bob=-1)], 8)
    else:
        add("walk", [human(kind, i, "fist" if i % 2 else "down") for i in range(4)], 6)
        add("hurt", [human(kind, 0, "up", hurt=True)], 1, False)
    sheet(frames, path + ".png")
    with open(path + ".json", "w") as f:
        json.dump({"frame_w": 16, "frame_h": 24, "anims": anims}, f, indent=1)


# ---------------------------------------------------------------- pecora
def sheep(head=0):
    cv = Canvas(24, 16)
    for x, y in ((1, 2), (3, 4), (-1, 6), (1, 7), (-2, 3)):
        pass
    for (x, y, r) in ((6, 7, 3.5), (10, 5, 3.6), (14, 6, 3.4), (7, 10, 3.2),
                      (12, 10, 3.4), (16, 9, 3), (4, 9, 2.6)):
        cv.circle(x, y, r, "w")
    cv.set(9, 4, "W"); cv.set(12, 9, "W"); cv.set(6, 10, "W")
    for lx in (6, 9, 13, 16):
        cv.line(lx, 12, lx, 15, "K")
    cv.ellipse(20, 6 + head, 3, 2.5, "K")
    cv.set(18, 4 + head, "K"); cv.set(17, 4 + head, "K")  # orecchio
    cv.set(21, 5 + head, "w")
    cv.outline("k")
    return cv


def build_sheep(path):
    sheet([sheep(0), sheep(1)], path + ".png")
    with open(path + ".json", "w") as f:
        json.dump({"frame_w": 24, "frame_h": 16,
                   "anims": {"idle": {"start": 0, "count": 2, "fps": 2, "loop": True}}}, f, indent=1)


# ---------------------------------------------------------------- oggetti
def butterfly(open_=True):
    cv = Canvas(16, 16)
    if open_:
        cv.ellipse(4, 6, 3.5, 4, "o"); cv.ellipse(12, 6, 3.5, 4, "o")
        cv.ellipse(5, 11, 2.5, 2.5, "y"); cv.ellipse(11, 11, 2.5, 2.5, "y")
        cv.circle(4, 5, 1, "k"); cv.circle(12, 5, 1, "k")
    else:
        cv.ellipse(6, 7, 2, 4, "o"); cv.ellipse(10, 7, 2, 4, "o")
        cv.ellipse(6, 11, 1.5, 2, "y"); cv.ellipse(10, 11, 1.5, 2, "y")
    cv.line(8, 4, 8, 13, "K")
    cv.line(8, 4, 6, 1, "K"); cv.line(8, 4, 10, 1, "K")
    cv.outline("k")
    return cv


def bottle():
    cv = Canvas(16, 16)
    cv.rect(5, 6, 6, 9, "G")
    cv.rect(6, 4, 4, 2, "G")
    cv.rect(7, 1, 2, 3, "G")
    cv.rect(7, 0, 2, 1, "y")
    cv.rect(5, 9, 6, 3, "w")
    cv.line(6, 10, 9, 10, "r")
    cv.line(6, 6, 6, 8, "g"); cv.set(6, 13, "g")
    cv.outline("k")
    return cv


def mushroom(glow=False):
    cv = Canvas(16, 16)
    cv.rect(6, 8, 4, 7, "w")
    cv.set(6, 14, "W"); cv.set(9, 9, "W")
    cv.ellipse(8, 6, 6.5, 4, "p" if not glow else "v")
    cv.rect(2, 7, 13, 2, "P")
    for x, y in ((5, 4), (10, 3), (8, 6), (12, 6), (3, 6)):
        cv.set(x, y, "w")
    cv.set(4, 4, "w")
    cv.outline("k")
    return cv


def poop(fly=0):
    cv = Canvas(16, 16)
    cv.ellipse(8, 13, 6, 2.2, "n")
    cv.ellipse(8, 10, 4.5, 2, "n")
    cv.ellipse(8, 7.5, 3, 1.6, "n")
    cv.ellipse(9, 5.5, 1.5, 1.2, "n")
    cv.line(4, 13, 11, 14, "N"); cv.line(5, 10, 10, 11, "N")
    cv.set(6, 12, "Y"); cv.set(7, 9, "Y")
    cv.outline("k")
    for (x, y) in ([(2, 2), (13, 4)], [(3, 4), (12, 1)])[fly]:
        cv.set(x, y, "k"); cv.set(x + 1, y - 1, "W")
    return cv


def uranium_plant(glow=0):
    cv = Canvas(16, 16)
    cv.line(8, 15, 8, 7, "G")
    cv.ellipse(5, 12, 3, 1.3, "g"); cv.ellipse(11, 10, 3, 1.3, "g")
    for a in range(6):
        ang = a * math.pi / 3
        cv.circle(8 + math.cos(ang) * 3, 5 + math.sin(ang) * 3, 1.6, "v")
    cv.circle(8, 5, 1.8, "t" if not glow else "y")
    cv.outline("k")
    if glow:
        for x, y in ((1, 2), (14, 3), (2, 8), (14, 8)):
            cv.set(x, y, "t")
    return cv


def mutant_plant(open_=0):
    cv = Canvas(16, 16)
    cv.line(8, 15, 8, 9, "G")
    cv.ellipse(4, 13, 3, 1.2, "G"); cv.ellipse(12, 12, 3, 1.2, "G")
    cv.ellipse(8, 6, 6, 4.5 + open_, "t")
    cv.rect(3, 6, 11, 1 + open_ * 2, "R")
    for x in range(4, 13, 2):
        cv.set(x, 6, "w")
        cv.set(x + 1, 6 + open_ * 2, "w")
    cv.set(6, 3, "y"); cv.set(10, 3, "y")
    cv.outline("k")
    return cv


def broom_item(t=0):
    cv = Canvas(16, 16)
    cv.line(2, 14, 13, 3, "n")
    cv.line(3, 14, 14, 3, "N")
    cv.poly([(0, 12), (5, 11), (5, 16), (0, 16)], "Y")
    cv.line(1, 13, 4, 13, "o")
    cv.outline("k")
    if t:
        cv.pattern(10, 9, [".#.#.", "#####", ".###.", "..#.."], {"#": "p"})
    return cv


def door(open_=False):
    cv = Canvas(32, 32)
    cv.rect(2, 2, 28, 30, "A")
    cv.rect(4, 4, 24, 28, "a" if not open_ else "k")
    if not open_:
        cv.circle(16, 15, 6, "y")
        for a in range(3):
            ang = a * 2 * math.pi / 3 - math.pi / 2
            for r in range(2, 6):
                for d in (-0.35, 0, 0.35):
                    cv.set(16 + math.cos(ang + d) * r, 15 + math.sin(ang + d) * r, "k")
        cv.circle(16, 15, 1, "k")
        cv.rect(6, 25, 20, 2, "W")
        cv.rect(24, 17, 2, 4, "W")
    else:
        cv.rect(8, 10, 16, 22, "P")
        cv.rect(10, 12, 12, 2, "p")
    for x, y in ((4, 4), (27, 4), (4, 29), (27, 29)):
        cv.set(x, y, "W")
    cv.outline("k")
    return cv


def crack(glow=False):
    cv = Canvas(32, 48)
    c = "k" if not glow else "p"
    pts = [(16, 0), (14, 6), (18, 12), (13, 19), (17, 25), (12, 32), (16, 39), (14, 47)]
    for i in range(len(pts) - 1):
        cv.line(*pts[i], *pts[i + 1], c)
        cv.line(pts[i][0] + 1, pts[i][1], pts[i + 1][0] + 1, pts[i + 1][1], c)
    for (x0, y0, x1, y1) in ((18, 12, 24, 15), (13, 19, 7, 21), (17, 25, 23, 29), (12, 32, 6, 35)):
        cv.line(x0, y0, x1, y1, c)
    cv.rect(14, 22, 4, 6, "k")
    if glow:
        cv.outline("v")
    return cv


def build_items(dir_):
    items = {
        "farfalla": [butterfly(True), butterfly(False)],
        "bottiglia": [bottle(), bottle()],
        "fungo": [mushroom(False), mushroom(True)],
        "merda": [poop(0), poop(1)],
        "uranio": [uranium_plant(0), uranium_plant(1)],
        "pianta_mutante": [mutant_plant(0), mutant_plant(1)],
        "scopa": [broom_item(0), broom_item(1)],
    }
    for name, fs in items.items():
        sheet(fs, f"{dir_}/{name}.png")
    sheet([door(False), door(True)], f"{dir_}/porta.png")
    sheet([crack(False), crack(True)], f"{dir_}/crepa.png")


def build_all(dir_):
    build_ladybug(f"{dir_}/coccinella")
    build_human("uomo", f"{dir_}/uomo")
    build_human("mutante", f"{dir_}/mutante")
    build_human("donna", f"{dir_}/donna")
    build_sheep(f"{dir_}/pecora")
    build_items(dir_)
