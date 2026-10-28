class_name Farmer
extends Node2D
## Arkadan kovalayan sinirli çiftçi. Her çarpışmada bir adım yaklaşır,
## MAX_HITS'te eşekleri yakalar.

signal caught

const MAX_HITS := 3
## Çarpışma sayısına göre çiftçinin ekran x konumu.
const STEPS := [8.0, 30.0, 50.0]

var hits := 0
var ground_y := 150.0
var catch_target_x := 90.0

var body: DataSprite
var _x_target: float = STEPS[0]
var _catching := false
var _shout: Label
var _shout_t := 0.0
var _t := 0.0


func setup(gy: float) -> void:
	ground_y = gy
	position = Vector2(-40.0, gy)
	body = DataSprite.new()
	body.bounce_hz = 4.0
	var tex := SpriteFactory.farmer()
	body.setup(Game.sprite_set("farmer"), {"run": tex, "catch": tex})
	add_child(body)

	_shout = Label.new()
	_shout.add_theme_font_size_override("font_size", 8)
	_shout.add_theme_color_override("font_color", Color("#fbf236"))
	_shout.add_theme_color_override("font_outline_color", Color("#120d16"))
	_shout.add_theme_constant_override("outline_size", 3)
	_shout.position = Vector2(-4, -50)
	_shout.visible = false
	add_child(_shout)


## Çarpışma: yaklaş. Yakaladıysa true döner.
func on_hit(text: String) -> bool:
	hits += 1
	shout(text)
	if hits >= MAX_HITS:
		_catching = true
		body.play("catch")
		return true
	_x_target = STEPS[hits]
	return false


func shout(text: String, duration := 1.4) -> void:
	_shout.text = text
	_shout.visible = true
	_shout_t = duration


func _process(delta: float) -> void:
	_t += delta
	if _catching:
		position.x = move_toward(position.x, catch_target_x - 14.0, 120.0 * delta)
		if absf(position.x - (catch_target_x - 14.0)) < 0.5 and _catching:
			_catching = false
			caught.emit()
	else:
		position.x = lerpf(position.x, _x_target + sin(_t * 1.3) * 3.0, 1.0 - exp(-2.5 * delta))
	if _shout_t > 0.0:
		_shout_t -= delta
		_shout.position.y = -50.0 + sin(_t * 20.0) * 1.0
		if _shout_t <= 0.0:
			_shout.visible = false
