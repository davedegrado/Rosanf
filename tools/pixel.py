"""Mini libreria di disegno pixel-art usata da generate_assets.py.

Disegna a risoluzione nativa (1 px = 1 pixel di gioco) su una griglia RGBA,
con un passaggio di contorno automatico per lo stile "sprite con outline".
"""
import math
import random
from PIL import Image

PAL = {
    "k": (26, 16, 24, 255),      # contorno
    "K": (46, 38, 52, 255),      # nero morbido (testa coccinella)
    "r": (214, 48, 49, 255),     # rosso guscio
    "R": (140, 24, 36, 255),     # rosso scuro
    "l": (255, 128, 110, 255),   # highlight
    "w": (244, 240, 224, 255),   # bianco
    "W": (190, 186, 176, 255),   # grigio chiaro
    "a": (120, 116, 112, 255),   # grigio
    "A": (70, 66, 70, 255),      # grigio scuro
    "s": (240, 190, 150, 255),   # pelle
    "S": (196, 134, 100, 255),   # pelle ombra
    "y": (250, 210, 60, 255),    # giallo
    "Y": (200, 140, 30, 255),    # ocra
    "o": (240, 120, 30, 255),    # arancio
    "g": (100, 186, 64, 255),    # verde
    "G": (40, 110, 48, 255),     # verde scuro
    "t": (170, 240, 70, 255),    # verde tossico
    "b": (70, 110, 200, 255),    # blu
    "B": (40, 60, 120, 255),     # blu scuro
    "p": (236, 90, 170, 255),    # rosa
    "P": (150, 40, 110, 255),    # magenta scuro
    "v": (150, 90, 200, 255),    # viola
    "n": (130, 80, 40, 255),     # marrone
    "N": (80, 46, 26, 255),      # marrone scuro
    "c": (110, 220, 230, 255),   # ciano
}

LCD_BG = (199, 240, 216, 255)
LCD_FG = (67, 82, 61, 255)


def col(c):
    if c is None:
        return (0, 0, 0, 0)
    if isinstance(c, str):
        return PAL[c]
    if len(c) == 3:
        return (c[0], c[1], c[2], 255)
    return c


class Canvas:
    def __init__(self, w, h, fill=None):
        self.w, self.h = w, h
        f = col(fill)
        self.px = [[f for _ in range(w)] for _ in range(h)]

    # --- primitive ---
    def set(self, x, y, c):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = col(c)

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.px[y][x]
        return (0, 0, 0, 0)

    def rect(self, x, y, w, h, c):
        for yy in range(int(y), int(y + h)):
            for xx in range(int(x), int(x + w)):
                self.set(xx, yy, c)

    def ellipse(self, cx, cy, rx, ry, c):
        for yy in range(int(cy - ry - 1), int(cy + ry + 2)):
            for xx in range(int(cx - rx - 1), int(cx + rx + 2)):
                dx = (xx - cx) / max(rx, 0.01)
                dy = (yy - cy) / max(ry, 0.01)
                if dx * dx + dy * dy <= 1.0:
                    self.set(xx, yy, c)

    def circle(self, cx, cy, r, c):
        self.ellipse(cx, cy, r, r, c)

    def line(self, x0, y0, x1, y1, c):
        n = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
        for i in range(n + 1):
            t = i / max(n, 1)
            self.set(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, c)

    def poly(self, pts, c):
        ys = [p[1] for p in pts]
        for y in range(int(min(ys)), int(max(ys)) + 1):
            xs = []
            for i in range(len(pts)):
                (x0, y0), (x1, y1) = pts[i], pts[(i + 1) % len(pts)]
                if (y0 <= y < y1) or (y1 <= y < y0):
                    xs.append(x0 + (y - y0) * (x1 - x0) / (y1 - y0))
            xs.sort()
            for i in range(0, len(xs) - 1, 2):
                for x in range(int(math.ceil(xs[i])), int(xs[i + 1]) + 1):
                    self.set(x, y, c)

    def pattern(self, x, y, rows, mapping=None):
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch in ". ":
                    continue
                c = mapping[ch] if mapping and ch in mapping else ch
                self.set(x + i, y + j, c)

    def outline(self, c="k", diagonal=False):
        oc = col(c)
        src = [row[:] for row in self.px]
        dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)]
        if diagonal:
            dirs += [(1, 1), (-1, -1), (1, -1), (-1, 1)]
        for y in range(self.h):
            for x in range(self.w):
                if src[y][x][3] != 0:
                    continue
                for dx, dy in dirs:
                    xx, yy = x + dx, y + dy
                    if 0 <= xx < self.w and 0 <= yy < self.h and src[yy][xx][3] != 0 and src[yy][xx] != oc:
                        self.px[y][x] = oc
                        break

    def blit(self, other, x, y, flip=False):
        for j in range(other.h):
            for i in range(other.w):
                c = other.px[j][other.w - 1 - i if flip else i]
                if c[3]:
                    self.set(x + i, y + j, c)

    def scaled(self, s):
        out = Canvas(self.w * s, self.h * s)
        for y in range(self.h):
            for x in range(self.w):
                c = self.px[y][x]
                if c[3]:
                    out.rect(x * s, y * s, s, s, c)
        return out

    def tint(self, fn):
        for y in range(self.h):
            for x in range(self.w):
                c = self.px[y][x]
                if c[3]:
                    self.px[y][x] = fn(c)

    def image(self):
        img = Image.new("RGBA", (self.w, self.h))
        img.putdata([p for row in self.px for p in row])
        return img

    def save(self, path):
        self.image().save(path)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def gradient(cv, top, bottom, y0=0, y1=None, bands=8):
    """Gradiente verticale a bande (dithering a scalini, look pixel)."""
    y1 = cv.h if y1 is None else y1
    for y in range(y0, y1):
        t = (y - y0) / max(1, (y1 - y0 - 1))
        t = math.floor(t * bands) / bands
        c = lerp(col(top), col(bottom), t)
        for x in range(cv.w):
            cv.set(x, y, c)


def sheet(frames, path):
    """Unisce frame della stessa dimensione in un'unica striscia orizzontale."""
    w, h = frames[0].w, frames[0].h
    out = Canvas(w * len(frames), h)
    for i, f in enumerate(frames):
        out.blit(f, i * w, 0)
    out.save(path)
    return out


def rng(seed):
    return random.Random(seed)
