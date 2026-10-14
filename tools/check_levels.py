#!/usr/bin/env python3
"""Controllo di raggiungibilità delle mappe (approssimato).

Simula in modo grossolano le capacità della coccinella: salto di MAX_RISE righe,
salto orizzontale di MAX_GAP colonne. Segnala oggetti e uscite irraggiungibili.
Uso: python3 tools/check_levels.py
"""
import glob
import os
import sys

MAX_RISE = 4      # righe (salto ~68 px con tile da 16)
MAX_GAP = 5       # colonne percorribili in salto
ITEM_REACH = 4    # righe sopra il piano in cui un oggetto si prende saltando
SOLID = "#="
TARGETS = "ubfxk*wECS"


def check(path):
    rows = [r.rstrip("\n") for r in open(path) if r.strip()]
    w = max(len(r) for r in rows)
    rows = [r.ljust(w, ".") for r in rows]
    h = len(rows)

    def solid(x, y):
        return 0 <= y < h and 0 <= x < w and rows[y][x] in SOLID

    def free(x, y):
        return 0 <= x < w and 0 <= y < h and rows[y][x] not in "#"

    stand = {(x, y) for y in range(h) for x in range(w) if free(x, y) and solid(x, y + 1) and rows[y][x] != "="}
    start = next((x, y) for y in range(h) for x in range(w) if rows[y][x] == "P")
    seen, todo = {start}, [start]
    while todo:
        x, y = todo.pop()
        for (nx, ny) in stand:
            if (nx, ny) in seen:
                continue
            dx, dy = abs(nx - x), y - ny  # dy>0 = più in alto
            if dy > MAX_RISE:
                continue
            gap = MAX_GAP + (max(0, -dy) // 2)  # cadendo si va più lontano
            if dx <= gap:
                seen.add((nx, ny))
                todo.append((nx, ny))
    bad = []
    for y in range(h):
        for x in range(w):
            c = rows[y][x]
            if c not in TARGETS:
                continue
            ok = any(sx == x and 0 <= sy - y <= ITEM_REACH for (sx, sy) in seen) or \
                any(abs(sx - x) <= 1 and 0 <= sy - y <= ITEM_REACH - 1 for (sx, sy) in seen)
            if c == "*":
                ok = ok or any(abs(sx - x) <= 3 and 0 <= sy - y <= ITEM_REACH for (sx, sy) in seen)
            if not ok:
                bad.append((c, x, y))
    return bad


def main():
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data", "levels")
    failed = False
    for p in sorted(glob.glob(os.path.join(root, "*.txt"))):
        bad = check(p)
        print(os.path.basename(p), "OK" if not bad else f"IRRAGGIUNGIBILI: {bad}")
        failed |= bool(bad)
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
