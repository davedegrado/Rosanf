# Rosanf?

Gioco 2D in pixel art per **Android e iOS** (e desktop), realizzato con **Godot 4.3**.
È tratto dal concept album sbrodol metal dei Rosanf. La protagonista è una coccinella antropomorfa.

> ⚠️ **Contenuti per adulti (18+)**: volgarità, violenza, alcol, droghe e sesso implicito.
> All'avvio il gioco chiede di confermare la maggiore età.

## Storia (3 capitoli)

| # | Capitolo | Genere | Gameplay |
|---|----------|--------|----------|
| 1 | **LA BOMBA** | metal forte | Platform: raccogli 5 piante radioattive (uranio), salva le donne, elimina gli umani, raggiungi il bunker. Gli umani saltano a tempo di musica. |
| 2 | **L'HAREM** | ballad lenta | Nel bunker: bevi (sbronza = controlli e camera ondeggiano), funghetti (sballo = shader psichedelico, salto più alto). La barra **NOIA** sale; con 10 "party" si attiva la crepa nel muro. |
| 3 | **L'IMPOTENZA** | caotico, generi misti | Mondo radioattivo: la barra **FAME** sale, si mangia merda per sopravvivere. Quando la musica passa al blast beat arriva la **FOLLIA** (controlli invertiti). Alla fine c'è la pecora. Finale aperto. |

Ogni capitolo ha una cutscene di intro e una di outro (pannelli pixel art + testo a macchina da scrivere).

## Avvio rapido

1. Installa [Godot 4.3](https://godotengine.org/download) (versione standard, non .NET).
2. Apri Godot → **Importa** → seleziona `project.godot`.
3. Premi **F5**.

Controlli da tastiera: **← →** / A D per muoversi (tenendo premuto si corre), **Spazio/Z** per saltare, **X/J** per attaccare, **Esc/P** per la pausa.
Il gamepad funziona. Su mobile compaiono i tasti touch ◀ ▶ **A** (salto) **B** (attacco) ⏸.
Su desktop puoi provare i tasti touch avviando con l'argomento `-- --touch`.

## Struttura del progetto

```
project.godot            configurazione (320x180, stretch viewport, landscape, GL Compatibility)
export_presets.cfg       preset di esportazione Android e iOS
autoload/
  game.gd                stato globale: impostazioni, salvataggio, flusso capitoli, testi UI (ITA/ENG)
  music.gd               musica + SFX + sincronizzazione ritmica (segnali beat / bar / cue)
  router.gd              cambi scena con dissolvenza
scenes/                  scene minime (la UI viene costruita dagli script)
scripts/
  ui/nokia_screen.gd     componente "schermo LCD Nokia 3310" riutilizzabile (menu, opzioni, pausa, game over)
  ui/*.gd                menu principale, capitoli, opzioni, pausa, HUD, controlli touch, verifica età
  cutscene/cutscene.gd   player di cutscene guidato da data/cutscenes.json
  level/level.gd         livello generico: legge la mappa ASCII e il capitolo da data/
  actors/player.gd       coccinella (coyote time, jump buffer, corsa, attacco, scopa, stati alterati)
  actors/enemy.gd        umani / mutanti
  actors/thing.gd        oggetti, NPC, pericoli e uscite
shaders/trip.gdshader    effetti sballo / sbronza / follia
data/
  chapters.json          definizione dei capitoli (obiettivi, musica, barre, cutscene)
  cutscenes.json         testi e immagini delle cutscene (ITA/ENG)
  music.json             brani, BPM, cue sincronizzati
  levels/cap*.txt        mappe ASCII dei livelli
assets/                  pixel art, font bitmap Nokia, audio (GENERATI, vedi sotto)
tools/                   generatore di asset e verifica dei livelli (Python)
tests/                   smoke test e screenshot automatici
docs/                    guide: livelli, musica, esportazione
```

## Asset

Tutta la grafica (sprite, tileset, sfondi parallax, illustrazioni, font Nokia, icone) e l'audio segnaposto
sono **generati da codice** e quindi si possono modificare e rigenerare:

```bash
pip install pillow numpy
python3 tools/generate_assets.py
```

Puoi sostituire qualsiasi PNG con una versione disegnata a mano (es. in Aseprite) mantenendo nome e dimensioni.
I fogli animati della coccinella e degli umani hanno un `.json` accanto che descrive le animazioni.

**La musica inclusa è un segnaposto chiptune.** Per usare i brani veri dei Rosanf vedi [docs/MUSICA.md](docs/MUSICA.md).

## Guide

- [docs/LIVELLI.md](docs/LIVELLI.md): legenda delle mappe e come aggiungere livelli o capitoli
- [docs/MUSICA.md](docs/MUSICA.md): come inserire i brani dei Rosanf e sincronizzare gli eventi
- [docs/EXPORT.md](docs/EXPORT.md): esportare per Android e iOS

## Test

```bash
# verifica che oggetti e uscite delle mappe siano raggiungibili
python3 tools/check_levels.py
# smoke test: apre tutte le schermate e gioca ogni capitolo con input simulato
godot --headless --path . res://tests/smoke_test.tscn
# screenshot (serve un display; su Linux headless: xvfb-run)
godot --path . res://tests/screenshots.tscn -- /percorso/output --touch
```
