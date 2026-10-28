extends Node2D
## Oyun sahnesi: dünya, iki eşek, çiftçi, HUD ve oyun sonu ekranı.

enum State { RUNNING, CAUGHT, OVER }

const PLAYER_X := 104.0
const PARTNER_X := 72.0
const FARMER_SHOUTS := ["GEL BURAYA!", "EŞŞEKLEEER!", "HAVUÇLARIM!", "DUR DEDİM!"]

var state := State.RUNNING
var world: World
var player: Donkey
var partner: Donkey
var farmer: Farmer
var seed_code := ""

var _hud: CanvasLayer
var _dist_label: Label
var _best_label: Label
var _code_label: Label
var _hits_bar: Control
var _over: Control
var _over_t := 0.0
var _shake := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	if Game.seed_code == "":
		Game.seed_code = Game.random_code()
	seed_code = Game.seed_code

	world = World.new()
	add_child(world)
	world.setup(Game.code_to_seed(seed_code))

	farmer = Farmer.new()
	add_child(farmer)
	farmer.setup(World.GROUND_Y)
	farmer.catch_target_x = PARTNER_X
	farmer.caught.connect(_on_caught)

	var me := Game.selected_character
	partner = Donkey.new()
	add_child(partner)
	partner.setup(Game.partner_of(me), AIController.new(), World.GROUND_Y)
	partner.position.x = PARTNER_X
	partner.crashed.connect(_on_crash)

	player = Donkey.new()
	add_child(player)
	player.setup(me, HumanController.new(), World.GROUND_Y)
	player.position.x = PLAYER_X
	player.crashed.connect(_on_crash)

	_build_hud()
	Audio.start_music()


func _physics_process(delta: float) -> void:
	if state == State.RUNNING:
		world.advance(delta)
	for d in [partner, player]:
		d.step(delta, world)
		if state == State.RUNNING:
			var o := world.check_collision(d)
			if not o.is_empty():
				d.take_hit(o)
	_update_hud()


func _process(delta: float) -> void:
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta)
		position = Vector2(_rng.randf_range(-2, 2), _rng.randf_range(-1, 1)) * (_shake / 0.25)
	else:
		position = Vector2.ZERO
	if state == State.OVER:
		_over_t += delta


func _on_crash(d: Donkey, _o: Dictionary) -> void:
	Audio.sfx("hit")
	Audio.sfx("hee")
	if not d.is_human():
		# Partnerin sakarlığı çiftçiyi yaklaştırmaz, sadece üzülür.
		return
	_shake = 0.25
	if farmer.on_hit(FARMER_SHOUTS[_rng.randi() % FARMER_SHOUTS.size()]):
		state = State.CAUGHT
		Audio.stop_music()
		for dk in [player, partner]:
			dk.frozen = true
			dk.hit_timer = 99.0


func _on_caught() -> void:
	state = State.OVER
	Audio.sfx("gameover")
	var m := world.meters()
	var record := Game.submit_distance(m)
	_show_game_over(m, record)


func _unhandled_input(event: InputEvent) -> void:
	if state == State.OVER and _over_t > 0.6 and event is InputEventScreenTouch and event.pressed:
		get_viewport().set_input_as_handled()
		get_tree().reload_current_scene()
	elif state == State.OVER and _over_t > 0.6 and event is InputEventKey and event.pressed and event.physical_keycode == KEY_SPACE:
		get_tree().reload_current_scene()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Audio.stop_music()
		get_tree().change_scene_to_file("res://scenes/menu.tscn")


# --- HUD -------------------------------------------------------------------

func _build_hud() -> void:
	_hud = CanvasLayer.new()
	add_child(_hud)
	_dist_label = UI.label("0 m", 16)
	_dist_label.position = Vector2(6, 2)
	_hud.add_child(_dist_label)
	_best_label = UI.label("Rekor %d m" % Game.best_m, 8, Color("#fbf236"))
	_best_label.position = Vector2(6, 22)
	_hud.add_child(_best_label)
	_code_label = UI.label("Oda: %s" % seed_code, 8, Color("#cbdbfc"))
	_code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_code_label.size = Vector2(120, 12)
	_code_label.position = Vector2(194, 4)
	_hud.add_child(_code_label)
	_hits_bar = Control.new()
	_hits_bar.position = Vector2(254, 18)
	_hits_bar.draw.connect(_draw_hits)
	_hud.add_child(_hits_bar)


func _draw_hits() -> void:
	# Çiftçiye kalan "can": 3 havuç, her çarpışmada biri yenir.
	for i in Farmer.MAX_HITS:
		var x := i * 20.0
		var alive := i >= farmer.hits
		var c := Color("#df7126") if alive else Color("#45283c")
		_hits_bar.draw_colored_polygon(PackedVector2Array([Vector2(x + 4, 2), Vector2(x + 12, 2), Vector2(x + 8, 14)]), c)
		_hits_bar.draw_rect(Rect2(x + 6, -1, 1, 3), Color("#6abe30") if alive else Color("#45283c"))
		_hits_bar.draw_rect(Rect2(x + 9, -1, 1, 3), Color("#6abe30") if alive else Color("#45283c"))


func _update_hud() -> void:
	_dist_label.text = "%d m" % world.meters()
	_hits_bar.queue_redraw()


func _show_game_over(m: int, record: bool) -> void:
	_over = Control.new()
	_over.set_anchors_preset(Control.PRESET_FULL_RECT)
	_over.size = Vector2(320, 180)
	_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_over)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.08, 0.72)
	dim.size = Vector2(320, 180)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over.add_child(dim)
	var lines := [
		["YAKALANDINIZ!", 12, Color("#ac3232"), 18.0],
		["%d m" % m, 40, Color.WHITE, 36.0],
		["Oda kodu: %s" % seed_code, 16, Color("#5fcde4"), 92.0],
		["YENİ REKOR!" if record else "Rekor: %d m" % Game.best_m, 10, Color("#fbf236"), 118.0],
		["Tekrar koşmak için dokun", 8, Color("#cbdbfc"), 150.0],
	]
	for ln in lines:
		var l := UI.label(ln[0], ln[1], ln[2], 4)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.size = Vector2(320, ln[1] + 6)
		l.position = Vector2(0, ln[3])
		_over.add_child(l)
