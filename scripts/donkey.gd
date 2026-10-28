class_name Donkey
extends Node2D
## Koşan eşek. position = ayakların ekran konumu (x sabit, y zıplamayla değişir).

signal crashed(donkey: Donkey, obstacle: Dictionary)

const GRAVITY := 720.0
const FAST_FALL := 1400.0
const JUMP_V := -232.0
const COYOTE := 0.08
const HIT_TIME := 0.8
const INVULN_TIME := 1.3

var char_id := ""
var controller: PlayerController
var ground_y := 150.0
var accent := Color.WHITE

var vel_y := 0.0
var on_ground := true
var ducking := false
var hit_w := 16.0
var hit_h := 26.0
var duck_h := 12.0
var hit_timer := 0.0
var invuln := 0.0
var frozen := false              # oyun bitince hareketsiz

var body: DataSprite
var avatar: Sprite2D
var _air_time := 0.0
var _t := 0.0
var _avatar_size := 16.0


func setup(id: String, ctrl: PlayerController, gy: float) -> void:
	char_id = id
	ground_y = gy
	position.y = gy
	var cdef := Game.character_def(id)
	accent = Color(str(cdef.get("accent", "#ffffff")))
	var sdef := Game.sprite_set(str(cdef.get("sprite_set", "donkey")))
	var hb: Dictionary = sdef.get("hitbox", {})
	hit_w = float(hb.get("w", hit_w))
	hit_h = float(hb.get("h", hit_h))
	duck_h = float(hb.get("duck_h", duck_h))
	_avatar_size = float(sdef.get("avatar_size", 16))

	body = DataSprite.new()
	var happy := SpriteFactory.donkey(false)
	body.setup(sdef, {"run": happy, "jump": happy, "duck": happy, "hit": SpriteFactory.donkey(true)})
	add_child(body)

	avatar = Sprite2D.new()
	var atex := Game.load_texture(str(cdef.get("avatar", "")))
	if atex == null:
		atex = SpriteFactory.avatar(accent)
	avatar.texture = atex
	avatar.scale = Vector2.ONE * (_avatar_size / float(atex.get_height()))
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/avatar_circle.gdshader")
	mat.set_shader_parameter("ring_color", accent)
	avatar.material = mat
	add_child(avatar)

	controller = ctrl
	controller.donkey = self
	add_child(controller)


func is_human() -> bool:
	return controller != null and controller.is_human()


## Çarpışma kutusu (ekran koordinatı).
func hitbox() -> Rect2:
	var h := duck_h if ducking else hit_h
	return Rect2(position.x - hit_w / 2.0, position.y - h, hit_w, h)


func step(delta: float, world: Node) -> void:
	_t += delta
	hit_timer = maxf(0.0, hit_timer - delta)
	invuln = maxf(0.0, invuln - delta)
	if frozen:
		_update_visual()
		return
	controller.update(delta, world)

	ducking = controller.wants_duck() and hit_timer <= 0.0
	if on_ground:
		_air_time = 0.0
	else:
		_air_time += delta
	var can_jump := (on_ground or _air_time < COYOTE) and vel_y >= 0.0 and hit_timer <= 0.0
	if can_jump and controller.wants_jump():
		vel_y = JUMP_V
		on_ground = false
		_air_time = COYOTE
		ducking = false
		Audio.sfx("jump" if is_human() else "jump_ai")

	if not on_ground:
		vel_y += (FAST_FALL if ducking else GRAVITY) * delta
		position.y += vel_y * delta
		if position.y >= ground_y:
			position.y = ground_y
			vel_y = 0.0
			on_ground = true
	_update_visual()


func take_hit(obstacle: Dictionary) -> void:
	if invuln > 0.0:
		return
	hit_timer = HIT_TIME
	invuln = INVULN_TIME
	ducking = false
	if obstacle.get("kind", "") == "pit":
		# Çukurdan zıplayarak çıkar.
		vel_y = -170.0
		on_ground = false
	crashed.emit(self, obstacle)


func _update_visual() -> void:
	body.vel_y = vel_y
	if hit_timer > 0.0:
		body.play("hit")
	elif not on_ground:
		body.play("jump")
	elif ducking:
		body.play("duck")
	else:
		body.play("run")
	# Çarpışma sonrası yanıp sönme.
	visible = invuln <= 0.0 or hit_timer > 0.0 or int(_t * 14.0) % 2 == 0
	var head := body.display_height * (0.55 if ducking else 1.0)
	avatar.position = Vector2(0, -head - _avatar_size / 2.0 - 3.0 + sin(_t * 3.0) * 1.5)
	avatar.rotation = sin(_t * 2.0) * 0.08
