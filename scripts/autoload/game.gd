extends Node
## Global oyun durumu: veri dosyaları, seçili karakter, oda kodu (seed), rekor.

const SAVE_PATH := "user://save.cfg"
const CODE_ALPHABET := "ABCDEFGHJKLMNPRSTUVYZ23456789"

var sprites_data: Dictionary = {}
var selected_character := "ismet"
var seed_code := ""
var best_m := 0

var _tex_cache: Dictionary = {}


func _ready() -> void:
	sprites_data = load_json("res://data/sprites.json")
	_load_save()


func load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("JSON açılamadı: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		return parsed
	push_error("JSON hatalı: %s" % path)
	return {}


func character_ids() -> Array:
	return sprites_data.get("characters", {}).keys()


func character_def(id: String) -> Dictionary:
	return sprites_data.get("characters", {}).get(id, {})


func sprite_set(name: String) -> Dictionary:
	return sprites_data.get("sprite_sets", {}).get(name, {})


func partner_of(id: String) -> String:
	for other in character_ids():
		if other != id:
			return other
	return id


## Asset varsa yükler, yoksa null döner (çağıran placeholder kullanır).
func load_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if _tex_cache.has(path):
		return _tex_cache[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_tex_cache[path] = tex
	return tex


# --- Seed / oda kodu -------------------------------------------------------

func normalize_code(code: String) -> String:
	return code.strip_edges().to_upper()


func code_to_seed(code: String) -> int:
	return normalize_code(code).hash()


func random_code() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var s := ""
	for i in 5:
		s += CODE_ALPHABET[rng.randi_range(0, CODE_ALPHABET.length() - 1)]
	return s


# --- Kayıt -----------------------------------------------------------------

func _load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	best_m = int(cfg.get_value("stats", "best_m", 0))
	selected_character = str(cfg.get_value("prefs", "character", selected_character))
	seed_code = str(cfg.get_value("prefs", "last_code", ""))
	if not character_ids().has(selected_character):
		selected_character = "ismet"


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("stats", "best_m", best_m)
	cfg.set_value("prefs", "character", selected_character)
	cfg.set_value("prefs", "last_code", seed_code)
	cfg.save(SAVE_PATH)


## Yeni rekorsa kaydeder ve true döner.
func submit_distance(m: int) -> bool:
	if m > best_m:
		best_m = m
		save()
		return true
	return false
