class_name Background
extends Node2D
## Parallax arka plan. Her katman themes.json'daki bir şekil (placeholder) ya da
## 'sprite' verilmişse yatayda tekrarlanan bir doku. Tema değişince 1 sn çapraz geçiş.

const W := 320.0
const H := 180.0
const FADE_TIME := 1.2

var world: World
var themes: ThemeManager
var current := -1
var previous := -1
var _fade := 1.0
var _t := 0.0
var _tex_cache: Dictionary = {}


func _process(delta: float) -> void:
	_t += delta
	if _fade < 1.0:
		_fade = minf(1.0, _fade + delta / FADE_TIME)
	queue_redraw()


func set_theme(i: int, instant := false) -> void:
	if i == current:
		return
	previous = current
	current = i
	_fade = 1.0 if instant or previous < 0 else 0.0


func _draw() -> void:
	if themes == null or current < 0:
		return
	if _fade < 1.0 and previous >= 0:
		_draw_theme(themes.theme_by_index(previous), 1.0)
	_draw_theme(themes.theme_by_index(current), _fade)


func _tex(path: String) -> Texture2D:
	if not _tex_cache.has(path):
		_tex_cache[path] = Game.load_texture(path)
	return _tex_cache[path]


func _col(hex: Variant, a: float) -> Color:
	var c := Color(str(hex))
	c.a *= a
	return c


func _rand(i: int, salt: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + float(salt) * 78.233) * 43758.5453, 1.0)


func _draw_theme(th: Dictionary, a: float) -> void:
	var sky_tex := _tex(str(th.get("sky_sprite", "")))
	if sky_tex:
		draw_texture_rect(sky_tex, Rect2(0, 0, W, H), false, Color(1, 1, 1, a))
	else:
		var sky: Array = th.get("sky", ["#639bff", "#cbdbfc"])
		var top := _col(sky[0], a)
		var bot := _col(sky[1], a)
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, H), Vector2(0, H)]),
			PackedColorArray([top, top, bot, bot]))
	var layers: Array = th.get("layers", [])
	for li in layers.size():
		_draw_layer(layers[li], li, a)


func _draw_layer(L: Dictionary, salt: int, a: float) -> void:
	var factor := float(L.get("factor", 0.2))
	var off := world.scroll * factor if world else 0.0
	var tex := _tex(str(L.get("sprite", "")))
	if tex:
		# Doku katmanı: alt kenarı 'y'ye (zemin) hizalı ya da y'den başlar.
		var tw := float(tex.get_width())
		var ty := float(L.get("y", 150)) - float(tex.get_height()) if float(L.get("y", 0)) >= 100.0 else float(L.get("y", 0))
		var x := -fposmod(off, tw)
		while x < W:
			draw_texture(tex, Vector2(x, ty), Color(1, 1, 1, a))
			x += tw
		return
	var shape := str(L.get("shape", ""))
	var c := _col(L.get("color", "#ffffff"), a)
	var c2 := _col(L.get("color2", L.get("color", "#ffffff")), a)
	var y := float(L.get("y", 150))
	var h := float(L.get("h", 30))
	if shape == "sun":
		var p := Vector2(float(L.get("x", 250)), y)
		var r := float(L.get("r", 12))
		draw_circle(p, r + 3.0, _col(L.get("color2", "#ffffff"), a * 0.5))
		draw_circle(p, r, c)
		return
	var tile := float(L.get("tile", 64))
	var first := int(floorf(off / tile))
	var count := int(W / tile) + 2
	for k in count:
		var i := first + k
		var x := i * tile - off
		var r1 := _rand(i, salt)
		var r2 := _rand(i, salt + 31)
		match shape:
			"clouds":
				var cy := y + r1 * 30.0
				var cw := 16.0 + r2 * 18.0
				draw_circle(Vector2(x + 10, cy), cw * 0.35, c)
				draw_circle(Vector2(x + 10 + cw * 0.4, cy - 3), cw * 0.45, c)
				draw_circle(Vector2(x + 10 + cw * 0.8, cy), cw * 0.33, c)
			"hills":
				var hh := h * (0.6 + r1 * 0.4)
				var pts := PackedVector2Array()
				var steps := 12
				for s in steps + 1:
					var u := float(s) / steps
					pts.append(Vector2(x + u * tile * 1.3 - tile * 0.15, y - sin(u * PI) * hh))
				pts.append(Vector2(x + tile * 1.15, y))
				pts.append(Vector2(x - tile * 0.15, y))
				draw_colored_polygon(pts, c)
			"trees":
				var th2 := h * (0.6 + r1 * 0.4)
				var tx := x + r2 * (tile - 16.0)
				draw_rect(Rect2(tx + 6, y - th2 * 0.35, 4, th2 * 0.35), c2)
				draw_colored_polygon(PackedVector2Array([Vector2(tx, y - th2 * 0.3), Vector2(tx + 8, y - th2), Vector2(tx + 16, y - th2 * 0.3)]), c)
				draw_colored_polygon(PackedVector2Array([Vector2(tx + 1, y - th2 * 0.55), Vector2(tx + 8, y - th2 * 1.15), Vector2(tx + 15, y - th2 * 0.55)]), c)
			"buildings":
				var bh := h * (0.45 + r1 * 0.55)
				var bw := tile - 4.0
				draw_rect(Rect2(x, y - bh, bw, bh), c)
				var wy := y - bh + 4.0
				var row := 0
				while wy < y - 4.0:
					var wx := x + 3.0
					var col := 0
					while wx < x + bw - 4.0:
						if _rand(i * 31 + row * 7 + col, salt) > 0.55:
							var blink := _rand(i + row + col, int(_t * 0.5)) > 0.97
							if not blink:
								draw_rect(Rect2(wx, wy, 2, 2), c2)
						wx += 5.0
						col += 1
					wy += 6.0
					row += 1
			"stars":
				for s2 in 3:
					var sx := x + _rand(i * 3 + s2, salt) * tile
					var sy := y + _rand(i * 3 + s2, salt + 7) * h
					var tw2 := 0.5 + 0.5 * sin(_t * (2.0 + s2) + i)
					var sc := c
					sc.a *= 0.4 + 0.6 * tw2
					draw_rect(Rect2(sx, sy, 1, 1), sc)
			"cacti":
				if r1 > 0.35:
					var cx := x + r2 * (tile - 10.0)
					var ch := h * (0.6 + r1 * 0.4)
					draw_rect(Rect2(cx + 3, y - ch, 4, ch), c)
					draw_rect(Rect2(cx, y - ch * 0.7, 3, 2), c)
					draw_rect(Rect2(cx, y - ch * 0.95, 2, 6), c)
					draw_rect(Rect2(cx + 7, y - ch * 0.55, 3, 2), c)
					draw_rect(Rect2(cx + 8, y - ch * 0.8, 2, 6), c)
					draw_rect(Rect2(cx + 4, y - ch + 1, 1, ch - 2), c2)
			"planets":
				if r1 > 0.3:
					var pr := 5.0 + r2 * 12.0
					var pc := Vector2(x + tile * 0.5, y + (r1 - 0.5) * 50.0)
					draw_circle(pc, pr, c)
					draw_circle(pc + Vector2(-pr * 0.3, -pr * 0.3), pr * 0.35, c2)
					if r2 > 0.5:
						draw_line(pc + Vector2(-pr * 1.6, pr * 0.3), pc + Vector2(pr * 1.6, -pr * 0.3), c2, 1.0)
			"crowd":
				var bob := absf(sin(_t * 6.0 + i * 1.3)) * 2.0
				draw_rect(Rect2(x, y + 4, tile, 40), c)
				draw_circle(Vector2(x + tile * 0.5, y - bob), 4.0, c)
				if r1 > 0.8:
					draw_rect(Rect2(x + tile * 0.5 - 1, y - 12 - bob, 2, 6), c2)
			"pillars":
				var ph := h * (0.7 + r1 * 0.3)
				draw_rect(Rect2(x + 10, y - ph, 14, ph), c)
				draw_rect(Rect2(x + 7, y - ph - 4, 20, 4), c2)
				draw_rect(Rect2(x + 13, y - ph + 3, 2, ph - 6), c2)
			"platforms":
				if r1 > 0.25:
					var pw := 30.0 + r2 * 30.0
					var py := y + (r1 - 0.5) * 30.0 + sin(_t * 1.5 + i) * 2.0
					draw_rect(Rect2(x, py, pw, 8), c)
					var sxp := 0.0
					while sxp < pw:
						draw_rect(Rect2(x + sxp, py, 4, 8), c2)
						sxp += 10.0
