"""Musiche segnaposto chiptune/metal e SFX sintetizzati.

Sono PLACEHOLDER: vanno sostituiti con i brani dei Rosanf (vedi docs/MUSICA.md).
BPM e lunghezza in battute corrispondono a data/music.json.
"""
import wave
import numpy as np

SR = 22050
NOTES = {"C": -9, "C#": -8, "D": -7, "D#": -6, "E": -5, "F": -4, "F#": -3,
         "G": -2, "G#": -1, "A": 0, "A#": 1, "B": 2}


def hz(n):
    """'A4', 'E2', 'C#5' -> frequenza."""
    name, octv = n[:-1], int(n[-1])
    return 440.0 * 2 ** ((NOTES[name] + (octv - 4) * 12) / 12)


def env(n, a=0.005, r=0.05):
    e = np.ones(n)
    ai, ri = max(1, int(a * SR)), max(1, int(r * SR))
    e[:ai] = np.linspace(0, 1, ai)
    if ri < n:
        e[-ri:] *= np.linspace(1, 0, ri)
    return e


def osc(kind, f, dur, duty=0.5):
    t = np.arange(int(dur * SR)) / SR
    ph = (t * f) % 1.0
    if kind == "square":
        w = np.where(ph < duty, 1.0, -1.0)
    elif kind == "tri":
        w = 4 * np.abs(ph - 0.5) - 1
    elif kind == "saw":
        w = 2 * ph - 1
    else:
        w = np.sin(2 * np.pi * ph)
    return w


def tone(kind, note, dur, vol=0.3, duty=0.5, a=0.005, r=0.05, dist=0.0):
    w = osc(kind, hz(note), dur, duty)
    if dist:
        w = np.clip(w * (1 + dist * 6), -1, 1)
    return w * env(len(w), a, r) * vol


def power(note, dur, vol=0.22):
    """Power chord distorto (fondamentale + quinta + ottava)."""
    f = hz(note)
    t = np.arange(int(dur * SR)) / SR
    w = sum(2 * ((t * f * m) % 1.0) - 1 for m in (1, 1.498, 2.0))
    w = np.tanh(w * 3.5)
    return w * env(len(w), 0.002, 0.03) * vol


def kick(vol=0.6):
    n = int(0.15 * SR)
    t = np.arange(n) / SR
    f = 120 * np.exp(-t * 30) + 40
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 18) * vol


def snare(vol=0.35, seed=0):
    n = int(0.12 * SR)
    t = np.arange(n) / SR
    noise = np.random.default_rng(seed).uniform(-1, 1, n)
    return (noise * 0.8 + np.sin(2 * np.pi * 190 * t) * 0.3) * np.exp(-t * 25) * vol


def hat(vol=0.12, seed=1):
    n = int(0.04 * SR)
    noise = np.random.default_rng(seed).uniform(-1, 1, n)
    return noise * np.exp(-np.arange(n) / SR * 90) * vol


class Track:
    def __init__(self, bpm, bars, beats=4):
        self.bpm, self.beats = bpm, beats
        self.spb = 60.0 / bpm
        self.buf = np.zeros(int(self.spb * beats * bars * SR) + 1)

    def add(self, beat, w):
        i = int(beat * self.spb * SR)
        j = min(len(self.buf), i + len(w))
        if i < len(self.buf):
            self.buf[i:j] += w[: j - i]

    def save(self, path):
        write(path, self.buf)


def write(path, buf):
    peak = max(1e-6, np.max(np.abs(buf)))
    buf = buf / peak * 0.85 if peak > 0.85 else buf
    data = (buf * 32767).astype(np.int16)
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(data.tobytes())


# ---------------------------------------------------------------- brani
def menu(path):
    tr = Track(120, 8)
    mel = ["A4", "C5", "E5", "A5", "G5", "E5", "D5", "E5", "F4", "A4", "C5", "F5", "E5", "C5", "B4", "G4"]
    bass = ["A2", "A2", "F2", "F2", "C3", "C3", "G2", "E2"]
    for bar in range(8):
        tr.add(bar * 4, tone("tri", bass[bar], tr.spb * 3.8, 0.35))
        for k in range(4):
            note = mel[(bar * 2 + k // 2) % len(mel)] if k % 2 == 0 else mel[(bar * 2 + 1) % len(mel)]
            tr.add(bar * 4 + k, tone("square", note, tr.spb * 0.45, 0.12, 0.25))
        tr.add(bar * 4, kick(0.3)); tr.add(bar * 4 + 2, snare(0.15))
    tr.save(path)


def metal(path):
    """Capitolo 1 — metal forte, 180 BPM."""
    tr = Track(180, 8)
    riff = ["E2", "E2", "E2", "G2", "E2", "E2", "A#2", "A2"]
    for bar in range(8):
        root = "E2" if bar < 6 else ("C3" if bar == 6 else "D3")
        for e in range(8):  # crome palm-mute
            n = riff[e] if bar < 6 else root
            tr.add(bar * 4 + e * 0.5, power(n, tr.spb * 0.42, 0.25))
        for b in range(4):
            tr.add(bar * 4 + b, kick(0.55)); tr.add(bar * 4 + b + 0.5, kick(0.4))
            tr.add(bar * 4 + b, hat(0.1, b)); tr.add(bar * 4 + b + 0.5, hat(0.08, b + 7))
        tr.add(bar * 4 + 1, snare(0.4, bar)); tr.add(bar * 4 + 3, snare(0.4, bar + 30))
        if bar >= 4:  # urlo/lead acuto
            for k, n in enumerate(["E5", "G5", "A#5", "B5"]):
                tr.add(bar * 4 + k, tone("saw", n, tr.spb * 0.9, 0.08, dist=0.6))
    tr.save(path)


def ballad(path):
    """Capitolo 2 — ballad lenta, 72 BPM."""
    tr = Track(72, 4)
    chords = [("A3", "C4", "E4"), ("F3", "A3", "C4"), ("C3", "E3", "G3"), ("G3", "B3", "D4")]
    lead = ["E5", "D5", "C5", "B4", "C5", "A4", "G4", "B4"]
    for bar, ch in enumerate(chords):
        tr.add(bar * 4, tone("tri", ch[0][:-1] + "2", tr.spb * 4, 0.3, a=0.05, r=0.5))
        for e in range(8):
            tr.add(bar * 4 + e * 0.5, tone("tri", ch[e % 3] if e < 6 else ch[(e + 1) % 3], tr.spb * 0.9, 0.14, r=0.3))
        tr.add(bar * 4, tone("square", lead[bar * 2], tr.spb * 1.8, 0.07, 0.125, a=0.08, r=0.4))
        tr.add(bar * 4 + 2, tone("square", lead[bar * 2 + 1], tr.spb * 1.8, 0.07, 0.125, a=0.08, r=0.4))
        tr.add(bar * 4, kick(0.2)); tr.add(bar * 4 + 2, snare(0.1, bar))
    tr.save(path)


def chaos(path):
    """Capitolo 3 — caotico, generi misti (polka / blast beat / valzer storto), 150 BPM."""
    tr = Track(150, 8)
    for bar in range(4):  # polka
        for b in range(4):
            tr.add(bar * 4 + b, tone("tri", ["C3", "G2"][b % 2], tr.spb * 0.4, 0.3) if b % 2 == 0 else
                   tone("square", "E4", tr.spb * 0.3, 0.1, 0.25))
        for k, n in enumerate(["G5", "E5", "C5", "E5", "G5", "C6", "B5", "G5"]):
            tr.add(bar * 4 + k * 0.5, tone("square", n, tr.spb * 0.3, 0.08, 0.5))
    for bar in range(4, 6):  # blast beat
        for s in range(16):
            tr.add(bar * 4 + s * 0.25, kick(0.4) if s % 2 == 0 else snare(0.3, s))
            tr.add(bar * 4 + s * 0.25, power(["E2", "F2"][s // 4 % 2], tr.spb * 0.22, 0.2))
    for bar in range(6, 8):  # "valzer" in 3 su 4 battiti: sghembo apposta
        for b in range(4):
            tr.add(bar * 4 + b, tone("tri", ["D3", "A3", "A3", "F#3"][b], tr.spb * 0.6, 0.25))
            tr.add(bar * 4 + b, tone("saw", ["F#5", "A5", "D6", "C#6"][b], tr.spb * 0.8, 0.06, dist=0.3))
    tr.save(path)


def drone(path):
    tr = Track(80, 4)
    for bar in range(4):
        tr.add(bar * 4, tone("tri", ["A2", "A2", "F2", "E2"][bar], tr.spb * 4, 0.3, a=0.3, r=0.6))
        tr.add(bar * 4, tone("square", ["E4", "C4", "A3", "G#3"][bar], tr.spb * 4, 0.05, 0.125, a=0.6, r=0.8))
    tr.save(path)


def gameover(path):
    tr = Track(100, 2)
    for k, n in enumerate(["E4", "D#4", "D4", "C#4"]):
        tr.add(k, tone("square", n, tr.spb * (0.9 if k < 3 else 3), 0.2, 0.5, r=0.2))
    tr.save(path)


# ---------------------------------------------------------------- sfx
def sweep(f0, f1, dur, kind="square", vol=0.3, duty=0.5):
    n = int(dur * SR)
    f = np.linspace(f0, f1, n)
    ph = np.cumsum(f) / SR % 1.0
    w = np.where(ph < duty, 1.0, -1.0) if kind == "square" else np.sin(2 * np.pi * ph)
    return w * env(n, 0.002, dur * 0.4) * vol


def noise_burst(dur, vol, decay):
    n = int(dur * SR)
    return np.random.default_rng(3).uniform(-1, 1, n) * np.exp(-np.arange(n) / SR * decay) * vol


def build_sfx(d):
    write(f"{d}/salto.wav", sweep(300, 700, 0.12))
    write(f"{d}/raccogli.wav", np.concatenate([tone("square", "E5", 0.06, 0.3), tone("square", "B5", 0.1, 0.3)]))
    write(f"{d}/colpo.wav", noise_burst(0.15, 0.6, 30) + sweep(200, 60, 0.15, "sine", 0.4))
    write(f"{d}/attacco.wav", noise_burst(0.08, 0.4, 60) + sweep(500, 200, 0.08, vol=0.15))
    write(f"{d}/menu_muovi.wav", tone("square", "A5", 0.03, 0.2, 0.25))
    write(f"{d}/menu_ok.wav", np.concatenate([tone("square", "C6", 0.04, 0.2), tone("square", "G6", 0.06, 0.2)]))
    write(f"{d}/esplosione.wav", noise_burst(1.6, 0.9, 3) * np.linspace(1, 0.2, int(1.6 * SR)))
    write(f"{d}/morte.wav", sweep(600, 80, 0.7, vol=0.3))
    write(f"{d}/bevi.wav", np.concatenate([sweep(200, 260, 0.08, "sine", 0.4)] * 3))
    write(f"{d}/mangia.wav", noise_burst(0.1, 0.4, 20) + sweep(120, 80, 0.1, "sine", 0.3))
    write(f"{d}/salva.wav", np.concatenate([tone("square", n, 0.06, 0.2) for n in ("C5", "E5", "G5", "C6")]))
    write(f"{d}/follia.wav", sweep(900, 100, 0.4, vol=0.25, duty=0.125) + sweep(100, 900, 0.4, vol=0.2))
    write(f"{d}/testo.wav", tone("square", "C6", 0.015, 0.1, 0.25))


def build_all(music_dir, sfx_dir):
    menu(f"{music_dir}/menu.wav")
    metal(f"{music_dir}/cap1_bomba.wav")
    ballad(f"{music_dir}/cap2_harem.wav")
    chaos(f"{music_dir}/cap3_impotenza.wav")
    drone(f"{music_dir}/cutscene.wav")
    gameover(f"{music_dir}/game_over.wav")
    build_sfx(sfx_dir)
