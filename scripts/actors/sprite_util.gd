class_name SpriteUtil
## Costruisce SpriteFrames a runtime dagli sheet generati (png + json opzionale).

static var _cache := {}


## Sheet con animazioni descritte da un .json {frame_w, frame_h, anims:{nome:{start,count,fps,loop}}}.
static func frames_from_sheet(base_path: String) -> SpriteFrames:
	if _cache.has(base_path):
		return _cache[base_path]
	var tex: Texture2D = load(base_path + ".png")
	var f := FileAccess.open(base_path + ".json", FileAccess.READ)
	var meta: Dictionary = JSON.parse_string(f.get_as_text())
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var fw := int(meta.frame_w)
	var fh := int(meta.frame_h)
	for anim_name in meta.anims:
		var a: Dictionary = meta.anims[anim_name]
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, float(a.fps))
		sf.set_animation_loop(anim_name, bool(a.loop))
		for i in int(a.count):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2((int(a.start) + i) * fw, 0, fw, fh)
			sf.add_frame(anim_name, at)
	_cache[base_path] = sf
	return sf


## Striscia orizzontale semplice: tutti i frame in un'unica animazione "default".
static func frames_strip(path: String, frame_w: int, fps := 4.0) -> SpriteFrames:
	var key := path + str(frame_w)
	if _cache.has(key):
		return _cache[key]
	var tex: Texture2D = load(path)
	var sf := SpriteFrames.new()
	sf.set_animation_speed("default", fps)
	for i in int(tex.get_width() / frame_w):
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * frame_w, 0, frame_w, tex.get_height())
		sf.add_frame("default", at)
	_cache[key] = sf
	return sf
