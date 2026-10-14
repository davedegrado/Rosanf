#!/usr/bin/env python3
"""Rigenera TUTTI gli asset del gioco (pixel art, font Nokia, audio segnaposto).

Uso:  python3 tools/generate_assets.py
Richiede: Pillow, numpy.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)

import font_nokia  # noqa: E402
import gen_sprites  # noqa: E402
import gen_world  # noqa: E402
import gen_audio  # noqa: E402


def p(*parts):
    path = os.path.join(ROOT, *parts)
    os.makedirs(os.path.dirname(path) if "." in os.path.basename(path) else path, exist_ok=True)
    return path


def main():
    font_nokia.build(p("assets", "fonts", "nokia.png"), p("assets", "fonts", "nokia.fnt"))
    gen_sprites.build_all(p("assets", "sprites"))
    gen_world.build_tiles(p("assets", "tiles", "tileset.png"))
    gen_world.build_backgrounds(p("assets", "backgrounds"))
    gen_world.build_cutscenes(p("assets", "cutscenes"))
    gen_world.build_ui(p("assets", "ui"), ROOT)
    gen_audio.build_all(p("assets", "audio", "music"), p("assets", "audio", "sfx"))
    print("Asset generati in", os.path.join(ROOT, "assets"))


if __name__ == "__main__":
    main()
