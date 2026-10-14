# Livelli e capitoli

## Mappe ASCII

Ogni livello è un file di testo in `data/levels/`. Un carattere corrisponde a una tile da 16×16 px.
Le mappe sono alte 12 righe (lo schermo ne mostra circa 11). La larghezza è libera.

| Carattere | Significato |
|-----------|-------------|
| `.` | vuoto |
| `#` | terreno solido (la tile "con erba" viene scelta in automatico se sopra è vuoto) |
| `=` | piattaforma attraversabile dal basso |
| `^` | pericolo (melma radioattiva / vetri rotti): toglie un cuore e fa rimbalzare |
| `P` | partenza della coccinella (**obbligatoria**) |
| `U` | umano (nemico) |
| `M` | umano mutante (più veloce, 2 colpi) |
| `u` | pianta radioattiva = uranio (obiettivo del cap. 1) |
| `b` | bottiglia: sbronza, abbassa la NOIA, conta come "party" |
| `f` | fungo: sballo e salto più alto, abbassa la NOIA, conta come "party" |
| `x` | merda: +1 cuore, abbassa la FAME |
| `k` | scopa: si vola per 7 secondi (SALTO = su) |
| `*` | farfalla: punti |
| `h` | pianta mutante: pericolo, apre la bocca a tempo di musica |
| `w` | donna da salvare (+200 punti) |
| `d` | donna che balla a tempo (decorazione) |
| `E` | porta del bunker, 2×2 tile; si apre a obiettivo raggiunto |
| `C` | crepa nel muro, 2×3 tile; si attiva a obiettivo raggiunto |
| `S` | pecora: tocca la pecora per finire il capitolo |
| `1`–`4` | decorazioni del tema (fiori, sassi, bottiglie, teschi…) |

Le uscite (`E`, `C`) e i personaggi alti si appoggiano sulla riga in cui sono scritti.

**Limiti di salto:** la coccinella sale al massimo di 4 righe e salta buchi larghi fino a circa 5 colonne.
Dopo aver modificato una mappa, lancia:

```bash
python3 tools/check_levels.py
```

Lo script segnala oggetti e uscite che non si possono raggiungere.

## Aggiungere un capitolo

1. Crea la mappa `data/levels/cap4.txt`.
2. Aggiungi le cutscene in `data/cutscenes.json`. Le immagini sono PNG 192×108 in `assets/cutscenes/`.
3. Aggiungi un brano in `data/music.json`.
4. Aggiungi un oggetto all'array in `data/chapters.json`:

```json
{
  "id": 4,
  "title": {"it": "NUOVO CAPITOLO", "en": "NEW CHAPTER"},
  "genre": {"it": "grindcore", "en": "grindcore"},
  "icon": "res://assets/ui/capitolo_1.png",
  "map": "res://data/levels/cap4.txt",
  "theme": 2,
  "background": "nucleare",
  "music": "cap4",
  "intro": "cap4_intro",
  "outro": "cap4_outro",
  "goal": {"item": "uranio", "count": 3, "exit": "porta"},
  "hint": {"it": "...", "en": "..."},
  "goal_done": {"it": "...", "en": "..."},
  "meter": null,
  "enemies_hop_on_beat": true,
  "madness_cues": []
}
```

- `theme`: riga del tileset da usare (0 = esterno, 1 = bunker, 2 = zona nucleare).
- `background`: prefisso degli sfondi in `assets/backgrounds/` (`<nome>_far.png`, `<nome>_near.png`).
- `goal.item`: `uranio`, `festa` (bottiglie e funghi) oppure vuoto se basta raggiungere l'uscita.
- `meter`: barra che sale col tempo (`rise_per_sec`) e scende raccogliendo `refill_items`. Quando è piena perdi un cuore.
- `madness_cues`: nomi dei cue musicali che scatenano la FOLLIA (controlli invertiti per 8 battiti).

Il capitolo appare da solo in "Seleziona capitolo" e viene sbloccato quando finisci il precedente.

## Nuovi oggetti o nemici

- **Oggetti:** aggiungi il carattere in `ITEM_CHARS` (`scripts/level/level.gd`) e lo sprite in `SPRITES` (`scripts/actors/thing.gd`). L'effetto va nel `match` di `_on_thing()`.
- **Nemici:** aggiungi il carattere in `ENEMY_CHARS` e uno sheet `assets/sprites/<tipo>.png` + `.json` con l'animazione `walk` e `hurt`.
