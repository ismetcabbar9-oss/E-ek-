class_name ThemeManager
extends RefCounted
## themes.json'u okur. Tema, dünya üzerindeki mesafeye göre belirlenir:
## her tema segment_meters sürer, sonra sıradakine geçilir (döngü).

var themes: Array = []
var segment_px := 3300.0


func _init() -> void:
	var data := Game.load_json("res://data/themes.json")
	themes = data.get("themes", [])
	segment_px = float(data.get("segment_meters", 330)) * World.PX_PER_M
	if themes.is_empty():
		themes = [World.DEFAULT_THEME]


func index_at(world_x: float) -> int:
	return int(floorf(maxf(world_x, 0.0) / segment_px)) % themes.size()


func theme_by_index(i: int) -> Dictionary:
	return themes[i % themes.size()]


func theme_at(world_x: float) -> Dictionary:
	return theme_by_index(index_at(world_x))


## world_x'ten sonraki ilk tema sınırı (dünya px).
func next_boundary(world_x: float) -> float:
	return (floorf(maxf(world_x, 0.0) / segment_px) + 1.0) * segment_px
