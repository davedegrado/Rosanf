# Musica dei Rosanf e sincronizzazione

I brani in `assets/audio/music/` sono **segnaposto** generati da `tools/gen_audio.py`.
Servono solo a far funzionare il gioco e la sincronizzazione.

> Prima di pubblicare l'app servono i diritti dei brani: deve dare il consenso la band o chi detiene i master e le edizioni.

## Sostituire un brano

1. Copia il file nel progetto, ad esempio `assets/audio/music/la_bomba.ogg`. Sono consigliati OGG Vorbis (più leggeri) o WAV.
2. Se il brano deve andare in loop, nel pannello **Import** di Godot attiva *Loop* e premi *Reimport*. In alternativa lascia `"loop": true`: il gioco lo fa ripartire da solo.
3. Aggiorna `data/music.json`:

```json
"cap1": {
  "file": "res://assets/audio/music/la_bomba.ogg",
  "bpm": 172,
  "beats_per_bar": 4,
  "offset": 0.35,
  "loop": true,
  "cues": {"0": "riff", "64": "lead", "128": "blast"}
}
```

- `bpm`: tempo del brano.
- `offset`: secondi prima del primo battito (silenzio o intro senza tempo).
- `cues`: eventi con nome legati a un **battito** contato dall'inizio del brano (battuta × `beats_per_bar`).
  Con 4/4 la battuta 17 corrisponde al battito 64.

## Come funziona la sincronizzazione

L'autoload `Music` (`autoload/music.gd`) calcola la posizione nel brano compensando la latenza audio
(`AudioServer.get_time_since_last_mix()` e `get_output_latency()`) ed emette tre segnali:

| Segnale | Quando | Uso attuale nel gioco |
|---------|--------|------------------------|
| `beat(index)` | ogni battito | gli umani saltano (cap. 1), l'uranio pulsa, le piante mutanti mordono, le donne ballano, i cuori dell'HUD pulsano |
| `bar(index)` | ogni battuta | libero per nuovi effetti |
| `cue(name)` | sui battiti indicati in `cues` | il cue `blast` del cap. 3 scatena la FOLLIA (`madness_cues` in `chapters.json`) |

Puoi agganciare nuovi eventi da qualsiasi script:

```gdscript
func _ready():
    Music.cue.connect(_on_cue)

func _on_cue(name: String):
    if name == "assolo":
        camera_shake()
```

`Music.beat_phase()` restituisce la posizione (da 0 a 1) dentro il battito corrente. Serve per animazioni continue a tempo.

## Effetti sonori

Gli SFX sono in `assets/audio/sfx/*.wav` e si suonano con `Music.sfx("nome")`.
Per sostituirne uno basta sovrascrivere il file con lo stesso nome.
