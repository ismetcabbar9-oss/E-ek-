extends Control
## Açılış: karakter seçimi. Kartlardan birine dokunmak oyunu başlatır.

var _cards: Array = []
var _t := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("#3f3f74")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var title := UI.label("EŞŞEKLER", 24, Color("#fbf236"), 5)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(320, 30)
	title.position = Vector2(0, 2)
	add_child(title)
	var sub := UI.label("Çiftçi geliyor! Eşeğini seç:", 8, Color("#cbdbfc"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(320, 12)
	sub.position = Vector2(0, 32)
	add_child(sub)

	var ids := ["zeynep", "ismet"]
	for i in ids.size():
		_add_card(ids[i], Vector2(28 + i * 140, 48))

	var best := UI.label("Rekor: %d m" % Game.best_m, 8, Color("#fbf236"))
	best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best.size = Vector2(320, 12)
	best.position = Vector2(0, 166)
	add_child(best)
	_build_extra()


## Sonraki aşamalarda (oda kodu girişi) genişletilir.
func _build_extra() -> void:
	pass


func _add_card(id: String, pos: Vector2) -> void:
	var cdef := Game.character_def(id)
	var accent := Color(str(cdef.get("accent", "#ffffff")))
	var card := Button.new()
	card.position = pos
	card.size = Vector2(124, 92)
	card.focus_mode = Control.FOCUS_NONE
	var normal := UI.box(Color("#222034"), accent, 4, 2)
	var hover := UI.box(Color("#306082"), accent, 4, 2)
	if id == Game.selected_character:
		normal.bg_color = Color("#45283c")
	card.add_theme_stylebox_override("normal", normal)
	card.add_theme_stylebox_override("hover", hover)
	card.add_theme_stylebox_override("pressed", hover)
	card.pressed.connect(_on_pick.bind(id))
	add_child(card)

	var sdef := Game.sprite_set(str(cdef.get("sprite_set", "donkey")))
	var dtex := Game.load_texture(str(sdef.get("anims", {}).get("run", {}).get("texture", "")))
	if dtex == null:
		dtex = SpriteFactory.donkey(false)
	var donkey := TextureRect.new()
	donkey.texture = dtex
	donkey.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	donkey.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	donkey.size = Vector2(48, 44)
	donkey.position = Vector2(38, 30)
	donkey.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(donkey)

	var atex := Game.load_texture(str(cdef.get("avatar", "")))
	if atex == null:
		atex = SpriteFactory.avatar(accent)
	var av := TextureRect.new()
	av.texture = atex
	av.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	av.stretch_mode = TextureRect.STRETCH_SCALE
	av.size = Vector2(20, 20)
	av.position = Vector2(52, 8)
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/avatar_circle.gdshader")
	mat.set_shader_parameter("ring_color", accent)
	av.material = mat
	card.add_child(av)

	var name_l := UI.label(str(cdef.get("name", id)), 8, accent.lightened(0.4))
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.size = Vector2(124, 12)
	name_l.position = Vector2(0, 76)
	card.add_child(name_l)
	_cards.append({"donkey": donkey, "avatar": av, "phase": _cards.size() * 1.7})


func _process(delta: float) -> void:
	_t += delta
	for c in _cards:
		var s := absf(sin(_t * 3.0 + c.phase))
		c.donkey.position.y = 30.0 - s * 4.0
		c.avatar.position.y = 8.0 + sin(_t * 2.5 + c.phase) * 1.5


func _on_pick(id: String) -> void:
	Audio.sfx("select")
	Game.selected_character = id
	_before_start()
	Game.save()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _before_start() -> void:
	pass


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().quit()
