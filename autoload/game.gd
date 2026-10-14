extends Node
## Stato globale: impostazioni, salvataggi, progressione tra i capitoli, testi UI.

const SAVE_PATH := "user://rosanf.cfg"
const FONT_PATH := "res://assets/fonts/nokia.fnt"
const FONT_SIZE := 10
const MAX_HEARTS := 4
const START_LIVES := 3

const LCD_BG := Color8(199, 240, 216)
const LCD_FG := Color8(67, 82, 61)
const LCD_MID := Color8(140, 170, 140)
const PHONE := Color8(38, 52, 44)

const LEVEL_SCENE := "res://scenes/level/level.tscn"
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const CUTSCENE_SCENE := "res://scenes/cutscene/cutscene.tscn"
const GAME_OVER_SCENE := "res://scenes/ui/game_over.tscn"
const END_SCENE := "res://scenes/ui/the_end.tscn"

# --- impostazioni (0..4 per i volumi, come le tacche del Nokia)
var sfx_volume := 4
var music_volume := 3
var vibration := true
var language := "it"
var age_confirmed := false

# --- progressione
var unlocked_chapter := 1
var best_score := 0

# --- sessione di gioco
var chapters: Array = []
var cutscenes: Dictionary = {}
var chapter_index := 0          # indice in `chapters`
var score := 0
var score_at_chapter_start := 0
var lives := START_LIVES
var cutscene_id := ""
var cutscene_done := Callable()

var font: Font

const UI := {
	"new_game": {"it": "NUOVO GIOCO", "en": "NEW GAME"},
	"continue": {"it": "CONTINUA", "en": "CONTINUE"},
	"chapters": {"it": "CAPITOLI", "en": "CHAPTERS"},
	"options": {"it": "OPZIONI", "en": "OPTIONS"},
	"quit": {"it": "ESCI", "en": "QUIT"},
	"select": {"it": "SELEZIONA", "en": "SELECT"},
	"back": {"it": "INDIETRO", "en": "BACK"},
	"ok": {"it": "OK", "en": "OK"},
	"select_chapter": {"it": "SELEZIONA CAPITOLO", "en": "SELECT CHAPTER"},
	"audio": {"it": "AUDIO", "en": "SOUND"},
	"music": {"it": "MUSICA", "en": "MUSIC"},
	"vibration": {"it": "VIBRAZIONE", "en": "VIBRATION"},
	"language": {"it": "LINGUA", "en": "LANGUAGE"},
	"yes": {"it": "SI", "en": "ON"},
	"no": {"it": "NO", "en": "OFF"},
	"game_over": {"it": "GAME OVER", "en": "GAME OVER"},
	"retry": {"it": "RITENTA", "en": "RETRY"},
	"main_menu": {"it": "MENU PRINCIPALE", "en": "MAIN MENU"},
	"pause": {"it": "PAUSA", "en": "PAUSE"},
	"resume": {"it": "CONTINUA", "en": "RESUME"},
	"restart": {"it": "RICOMINCIA", "en": "RESTART"},
	"chapter": {"it": "CAPITOLO", "en": "CHAPTER"},
	"points": {"it": "PUNTI", "en": "SCORE"},
	"skip": {"it": "SALTA", "en": "SKIP"},
	"next": {"it": "AVANTI", "en": "NEXT"},
	"age_title": {"it": "ATTENZIONE 18+", "en": "WARNING 18+"},
	"age_body": {"it": "GIOCO PER ADULTI: VOLGARITÀ, VIOLENZA, ALCOL, DROGHE E SESSO (IMPLICITO). HAI ALMENO 18 ANNI?",
		"en": "ADULT GAME: PROFANITY, VIOLENCE, ALCOHOL, DRUGS AND (IMPLIED) SEX. ARE YOU AT LEAST 18?"},
	"age_yes": {"it": "SI, HO 18+ ANNI", "en": "YES, I'M 18+"},
	"age_no": {"it": "NO", "en": "NO"},
	"age_denied": {"it": "TORNA QUANDO SARAI GRANDE.", "en": "COME BACK WHEN YOU'RE OLDER."},
	"the_end": {"it": "FINE?", "en": "THE END?"},
	"best": {"it": "RECORD", "en": "BEST"},
	"saved": {"it": "SALVATA!", "en": "SAVED!"},
	"bunker_closed": {"it": "SERVE PIÙ URANIO!", "en": "NEED MORE URANIUM!"},
	"crack_closed": {"it": "NON ANCORA...", "en": "NOT YET..."},
	"madness": {"it": "FOLLIA!", "en": "MADNESS!"},
	"bored": {"it": "CHE NOIA!", "en": "SO BORING!"},
	"starving": {"it": "FAME!", "en": "STARVING!"},
	"drunk": {"it": "SBRONZA!", "en": "DRUNK!"},
	"high": {"it": "SBALLO!", "en": "HIGH!"},
	"broom": {"it": "SCOPA!", "en": "BROOM!"},
	"yum": {"it": "GNAM...", "en": "YUM..."},
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	_setup_theme()
	_load_data()
	load_settings()


# ------------------------------------------------------------------ testi
func tr_ui(key: String) -> String:
	var entry: Dictionary = UI.get(key, {})
	return entry.get(language, entry.get("it", key))


func loc(value) -> String:
	if value is Dictionary:
		return value.get(language, value.get("it", ""))
	return str(value)


# ------------------------------------------------------------------ setup
func _setup_theme() -> void:
	# Il tema globale (font Nokia) è in assets/ui/theme.tres, impostato in project.godot.
	font = load(FONT_PATH)


func _add_action(action: String, keys: Array, joy_buttons: Array = []) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
	for b in joy_buttons:
		var jb := InputEventJoypadButton.new()
		jb.button_index = b
		InputMap.action_add_event(action, jb)


func _setup_input() -> void:
	_add_action("move_left", [KEY_LEFT, KEY_A], [JOY_BUTTON_DPAD_LEFT])
	_add_action("move_right", [KEY_RIGHT, KEY_D], [JOY_BUTTON_DPAD_RIGHT])
	_add_action("move_up", [KEY_UP, KEY_W], [JOY_BUTTON_DPAD_UP])
	_add_action("move_down", [KEY_DOWN, KEY_S], [JOY_BUTTON_DPAD_DOWN])
	_add_action("jump", [KEY_SPACE, KEY_Z, KEY_K], [JOY_BUTTON_A])
	_add_action("attack", [KEY_X, KEY_J, KEY_CTRL], [JOY_BUTTON_X])
	_add_action("pause", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START])


func _load_data() -> void:
	chapters = _read_json("res://data/chapters.json").get("chapters", [])
	cutscenes = _read_json("res://data/cutscenes.json")


func _read_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Impossibile aprire %s" % path)
		return {}
	var data = JSON.parse_string(f.get_as_text())
	return data if data is Dictionary else {}


# ------------------------------------------------------------------ salvataggi
func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		sfx_volume = cfg.get_value("settings", "sfx", sfx_volume)
		music_volume = cfg.get_value("settings", "music", music_volume)
		vibration = cfg.get_value("settings", "vibration", vibration)
		language = cfg.get_value("settings", "language", language)
		age_confirmed = cfg.get_value("settings", "age_confirmed", false)
		unlocked_chapter = cfg.get_value("progress", "unlocked", 1)
		best_score = cfg.get_value("progress", "best_score", 0)
	apply_audio()


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "sfx", sfx_volume)
	cfg.set_value("settings", "music", music_volume)
	cfg.set_value("settings", "vibration", vibration)
	cfg.set_value("settings", "language", language)
	cfg.set_value("settings", "age_confirmed", age_confirmed)
	cfg.set_value("progress", "unlocked", unlocked_chapter)
	cfg.set_value("progress", "best_score", best_score)
	cfg.save(SAVE_PATH)


func apply_audio() -> void:
	Music.set_volumes(music_volume / 4.0, sfx_volume / 4.0)


func vibrate(ms: int = 60) -> void:
	if vibration:
		Input.vibrate_handheld(ms)


# ------------------------------------------------------------------ flusso di gioco
func current_chapter() -> Dictionary:
	return chapters[chapter_index]


func new_game() -> void:
	score = 0
	lives = START_LIVES
	start_chapter(0)


func continue_game() -> void:
	score = 0
	lives = START_LIVES
	start_chapter(clampi(unlocked_chapter - 1, 0, chapters.size() - 1))


func start_chapter(index: int, with_intro := true) -> void:
	chapter_index = index
	score_at_chapter_start = score
	var ch := current_chapter()
	if with_intro and ch.get("intro", "") != "":
		play_cutscene(ch.intro, func(): Router.goto(LEVEL_SCENE))
	else:
		Router.goto(LEVEL_SCENE)


func play_cutscene(id: String, on_done: Callable) -> void:
	cutscene_id = id
	cutscene_done = on_done
	Router.goto(CUTSCENE_SCENE)


func finish_cutscene() -> void:
	var cb := cutscene_done
	cutscene_done = Callable()
	if cb.is_valid():
		cb.call()
	else:
		Router.goto(MENU_SCENE)


func add_score(points: int) -> void:
	score += points
	if score > best_score:
		best_score = score


func complete_chapter() -> void:
	unlocked_chapter = maxi(unlocked_chapter, mini(chapter_index + 2, chapters.size()))
	save()
	var ch := current_chapter()
	var next := chapter_index + 1
	var after := func():
		if next < chapters.size():
			start_chapter(next)
		else:
			Router.goto(END_SCENE)
	if ch.get("outro", "") != "":
		play_cutscene(ch.outro, after)
	else:
		after.call()


func player_died() -> void:
	lives -= 1
	save()
	if lives < 0:
		Router.goto(GAME_OVER_SCENE)
	else:
		score = score_at_chapter_start
		Router.goto(LEVEL_SCENE)


func retry_after_game_over() -> void:
	lives = START_LIVES
	score = score_at_chapter_start
	start_chapter(chapter_index, false)
