class_name World
extends Node2D
## Kayan dünya: zemin, çukurlar ve engeller. Engel dizilimi tamamen seed'e ve
## mesafeye bağlıdır (kare süresine değil), böylece aynı oda kodu aynı parkuru üretir.

const GROUND_Y := 150.0
const VIEW_W := 320.0
const PX_PER_M := 10.0
const START_SPEED := 80.0
const MAX_SPEED := 150.0
const ACCEL_PER_M := 0.03          # her metrede +0.03 px/s
const FIRST_OBSTACLE_X := 420.0
const AIR_CLEARANCE := 17.0        # havadaki engelin yerden yüksekliği

const DEFAULT_THEME := {
	"ground": {"top": "#6abe30", "fill": "#8f563b", "detail": "#663931", "pit": "#1b1b2b"},
	"obstacles": {
		"low": {"shape": "box", "color": "#8f563b", "color2": "#d9a066"},
		"air": {"shape": "bird", "color": "#222034", "color2": "#ac3232"},
		"pit": {"shape": "hole", "color": "#1b1b2b", "color2": "#306082"},
	},
}

var scroll := 0.0                  # toplam kat edilen mesafe (px)
var speed := START_SPEED
var obstacles: Array = []          # {id, x, w, h, kind, theme}
var themes: Object = null          # ThemeManager (yoksa DEFAULT_THEME)

var _rng := RandomNumberGenerator.new()
var _next_x := FIRST_OBSTACLE_X
var _next_id := 0
var _tex_cache: Dictionary = {}


func setup(seed_value: int) -> void:
	_rng.seed = seed_value
	scroll = 0.0
	speed = START_SPEED
	obstacles.clear()
	_next_x = FIRST_OBSTACLE_X
	_next_id = 0
	_generate_until(VIEW_W + 200.0)


func meters() -> int:
	return int(scroll / PX_PER_M)


static func speed_at(px: float) -> float:
	return minf(MAX_SPEED, START_SPEED + (px / PX_PER_M) * ACCEL_PER_M)


func advance(delta: float) -> void:
	speed = speed_at(scroll)
	scroll += speed * delta
	_generate_until(scroll + VIEW_W + 200.0)
	while not obstacles.is_empty() and obstacles[0].x + obstacles[0].w < scroll - 64.0:
		obstacles.pop_front()
	queue_redraw()


func theme_at(world_x: float) -> Dictionary:
	if themes:
		return themes.theme_at(world_x)
	return DEFAULT_THEME


func theme_index_at(world_x: float) -> int:
	if themes:
		return themes.index_at(world_x)
	return 0


# --- Üretim ----------------------------------------------------------------

func _generate_until(limit: float) -> void:
	while _next_x < limit:
		_spawn_at(_next_x)


func _spawn_at(x: float) -> void:
	var kind: String
	# İlk üç engel öğretici: alçak, havada, çukur.
	if _next_id < 3:
		kind = ["low", "air", "pit"][_next_id]
	else:
		var r := _rng.randf()
		kind = "low" if r < 0.45 else ("air" if r < 0.75 else "pit")
	var o := {"id": _next_id, "x": x, "kind": kind, "theme": theme_index_at(x)}
	match kind:
		"low":
			o.w = float(_rng.randi_range(10, 16))
			o.h = float(_rng.randi_range(9, 15))
		"air":
			o.w = float(_rng.randi_range(16, 26))
			o.h = 10.0
		"pit":
			o.w = float(_rng.randi_range(20, 32))
			o.h = 0.0
	obstacles.append(o)
	_next_id += 1
	# Bir sonraki engele kadar boşluk: rahatça zıplayıp inebilecek kadar.
	var v := speed_at(x)
	var air_time := 2.0 * -Donkey.JUMP_V / Donkey.GRAVITY
	var min_gap: float = v * (air_time + 0.55) + o.w
	var extra := _rng.randf_range(0.0, v * 1.4)
	_next_x = x + min_gap + extra


# --- Sorgular --------------------------------------------------------------

func screen_x(world_x: float) -> float:
	return world_x - scroll


func screen_rect(o: Dictionary) -> Rect2:
	var sx := screen_x(o.x)
	match o.kind:
		"air":
			return Rect2(sx, GROUND_Y - AIR_CLEARANCE - o.h, o.w, o.h)
		"pit":
			return Rect2(sx, GROUND_Y, o.w, 180.0 - GROUND_Y)
	return Rect2(sx, GROUND_Y - o.h, o.w, o.h)


func obstacles_on_screen() -> Array:
	var out: Array = []
	for o in obstacles:
		var sx := screen_x(o.x)
		if sx > VIEW_W + 16.0:
			break
		if sx + o.w > -16.0:
			out.append(o)
	return out


## Eşeğin çarptığı engeli döner (yoksa boş sözlük). Kutular affedici olsun diye küçültülür.
func check_collision(d: Donkey) -> Dictionary:
	var hb := d.hitbox().grow_individual(-3.0, -2.0, -3.0, 0.0)
	for o in obstacles_on_screen():
		var r := screen_rect(o)
		if o.kind == "pit":
			var foot_x := d.position.x
			if d.on_ground and foot_x > r.position.x + 3.0 and foot_x < r.end.x - 3.0:
				return o
		elif hb.intersects(r.grow(-1.0)):
			return o
	return {}


# --- Çizim -----------------------------------------------------------------

func _texture(path: String) -> Texture2D:
	if not _tex_cache.has(path):
		_tex_cache[path] = Game.load_texture(path)
	return _tex_cache[path]


func _draw() -> void:
	_draw_ground()
	for o in obstacles_on_screen():
		if o.kind != "pit":
			_draw_obstacle(o)


func _draw_ground() -> void:
	# Zemin, tema sınırlarında dünyayla birlikte kayar.
	var x := 0.0
	while x < VIEW_W:
		var wx := scroll + x
		var seg_end := VIEW_W
		if themes:
			seg_end = minf(VIEW_W, themes.next_boundary(wx) - scroll)
		var g: Dictionary = theme_at(wx).ground
		var w := seg_end - x
		draw_rect(Rect2(x, GROUND_Y, w, 180.0 - GROUND_Y), Color(g.fill))
		draw_rect(Rect2(x, GROUND_Y, w, 3), Color(g.top))
		# Hareket hissi için kayan detay pikselleri.
		var detail := Color(g.detail)
		var start := floorf(wx / 16.0) * 16.0
		var px := start
		while px < scroll + seg_end:
			var lx := px - scroll
			if lx >= x - 2.0:
				var row := int(px / 16.0) % 3
				draw_rect(Rect2(lx + 4, GROUND_Y + 8 + row * 7, 3, 2), detail)
			px += 16.0
		x = seg_end
	for o in obstacles_on_screen():
		if o.kind == "pit":
			_draw_pit(o)


func _draw_pit(o: Dictionary) -> void:
	var r := screen_rect(o)
	var st: Dictionary = themes_obstacle(o, "pit")
	var tex_path := str(st.get("sprite", ""))
	if tex_path != "" and _texture(tex_path):
		draw_texture_rect(_texture(tex_path), r, false)
		return
	draw_rect(r, Color(st.color))
	# Yüzeyde dalgalanan sıvı/kenar çizgisi.
	var c2 := Color(st.color2)
	var t := Time.get_ticks_msec() / 1000.0
	var i := 0.0
	while i < r.size.x:
		var yy := r.position.y + 5.0 + sin(t * 4.0 + i * 0.5) * 1.5
		draw_rect(Rect2(r.position.x + i, yy, 2, 1), c2)
		i += 3.0
	draw_rect(Rect2(r.position.x, r.position.y, 1, r.size.y), c2.darkened(0.4))
	draw_rect(Rect2(r.end.x - 1, r.position.y, 1, r.size.y), c2.darkened(0.4))


func themes_obstacle(o: Dictionary, kind: String) -> Dictionary:
	var th: Dictionary = themes.theme_by_index(o.theme) if themes else DEFAULT_THEME
	return th.obstacles[kind]


func _draw_obstacle(o: Dictionary) -> void:
	var r := screen_rect(o)
	var st: Dictionary = themes_obstacle(o, o.kind)
	var tex_path := str(st.get("sprite", ""))
	if tex_path != "" and _texture(tex_path):
		var tex := _texture(tex_path)
		# Doku, çarpışma kutusuna altından hizalanır, oranı korunur.
		var s := r.size.y / float(tex.get_height()) if o.kind == "air" else r.size.x / float(tex.get_width())
		var size := Vector2(tex.get_width(), tex.get_height()) * maxf(s, 0.01)
		draw_texture_rect(tex, Rect2(Vector2(r.get_center().x - size.x / 2.0, r.end.y - size.y), size), false)
		return
	var c := Color(st.color)
	var c2 := Color(st.color2)
	var outline := Color("#120d16")
	var t := Time.get_ticks_msec() / 1000.0
	match str(st.shape):
		"box":
			draw_rect(r, outline)
			draw_rect(r.grow(-1), c)
			draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, 2)), c2)
			draw_line(r.position + Vector2(1, 1), r.end - Vector2(1, 1), c2.darkened(0.3))
		"stump":
			draw_rect(r, outline)
			draw_rect(r.grow(-1), c)
			draw_rect(Rect2(r.position.x + 1, r.position.y + 1, r.size.x - 2, 3), c2)
			draw_rect(Rect2(r.get_center().x - 1, r.position.y + 2, 2, 1), c.darkened(0.3))
		"spikes":
			var n := maxi(2, int(r.size.x / 5.0))
			var w := r.size.x / n
			for k in n:
				var bx := r.position.x + k * w
				draw_colored_polygon(PackedVector2Array([Vector2(bx, r.end.y), Vector2(bx + w / 2.0, r.position.y), Vector2(bx + w, r.end.y)]), c)
				draw_line(Vector2(bx + w / 2.0, r.position.y + 1), Vector2(bx + w / 2.0, r.end.y - 1), c2)
		"cactus":
			var cx := r.get_center().x
			draw_rect(Rect2(cx - 3, r.position.y, 6, r.size.y), outline)
			draw_rect(Rect2(cx - 2, r.position.y + 1, 4, r.size.y - 1), c)
			draw_rect(Rect2(r.position.x, r.position.y + 4, 3, 2), c)
			draw_rect(Rect2(r.position.x, r.position.y + 1, 2, 4), c)
			draw_rect(Rect2(r.end.x - 3, r.position.y + 6, 3, 2), c)
			draw_rect(Rect2(r.end.x - 2, r.position.y + 3, 2, 4), c)
			draw_rect(Rect2(cx - 1, r.position.y + 2, 1, r.size.y - 3), c2)
		"cone":
			draw_colored_polygon(PackedVector2Array([Vector2(r.position.x, r.end.y), Vector2(r.get_center().x, r.position.y), Vector2(r.end.x, r.end.y)]), c)
			draw_rect(Rect2(r.position.x + r.size.x * 0.25, r.position.y + r.size.y * 0.5, r.size.x * 0.5, 2), c2)
			draw_rect(Rect2(r.position.x - 1, r.end.y - 2, r.size.x + 2, 2), outline)
		"bumper":
			var rad := minf(r.size.x, r.size.y) / 2.0
			draw_circle(Vector2(r.get_center().x, r.end.y - rad), rad + 1.0, outline)
			draw_circle(Vector2(r.get_center().x, r.end.y - rad), rad, c)
			draw_circle(Vector2(r.get_center().x - rad * 0.3, r.end.y - rad * 1.4), rad * 0.3, c2)
		"bird":
			var flap := sin(t * 14.0) * 3.0
			draw_rect(Rect2(r.position.x + 4, r.position.y + 3, r.size.x - 8, 5), c)
			draw_colored_polygon(PackedVector2Array([Vector2(r.position.x + 6, r.position.y + 4), Vector2(r.get_center().x, r.position.y - flap), Vector2(r.end.x - 6, r.position.y + 4)]), c)
			draw_rect(Rect2(r.position.x + 1, r.position.y + 4, 3, 2), c2)
			draw_rect(Rect2(r.position.x + 5, r.position.y + 4, 1, 1), Color.WHITE)
		"bar":
			var swing := sin(t * 5.0) * 2.0
			draw_rect(Rect2(r.position.x, r.position.y + swing, r.size.x, r.size.y), outline)
			draw_rect(Rect2(r.position.x + 1, r.position.y + 1 + swing, r.size.x - 2, r.size.y - 2), c)
			var k := 0.0
			while k < r.size.x - 2:
				draw_rect(Rect2(r.position.x + 1 + k, r.position.y + 1 + swing, 3, r.size.y - 2), c2)
				k += 6.0
			draw_line(Vector2(r.get_center().x, 0), Vector2(r.get_center().x, r.position.y + swing), outline)
		"ufo":
			var bob := sin(t * 3.0) * 1.5
			var cc := r.get_center() + Vector2(0, bob)
			draw_circle(cc + Vector2(0, -2), 4.0, c2)
			draw_rect(Rect2(r.position.x, cc.y - 1, r.size.x, 4), outline)
			draw_rect(Rect2(r.position.x + 1, cc.y, r.size.x - 2, 2), c)
			for k2 in 3:
				draw_rect(Rect2(r.position.x + 3 + k2 * (r.size.x - 6) / 2.0, cc.y + 3, 1, 1), Color("#fbf236") if int(t * 6.0 + k2) % 2 == 0 else c2)
		"ball":
			var rr := r.size.y / 2.0 + 1.0
			var cx2 := r.get_center() + Vector2(sin(t * 6.0) * 2.0, 0)
			draw_circle(cx2, rr + 1.0, outline)
			draw_circle(cx2, rr, c)
			draw_rect(Rect2(cx2.x - rr, cx2.y - 1, rr * 2.0, 2), c2)
			draw_rect(Rect2(r.end.x, cx2.y - 1, 6, 1), c2.lightened(0.3))
		_:
			draw_rect(r, outline)
			draw_rect(r.grow(-1), c)
