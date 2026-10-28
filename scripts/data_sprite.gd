class_name DataSprite
extends Node2D
## sprites.json içindeki bir sprite_set'i oynatan bileşen.
## Origin = ayak hizası (ortalanmış alt nokta), böylece squash/stretch yerden yapılır.
## Asset dosyası yoksa verilen placeholder dokuyu kullanır.

var display_height := 30.0
var anims: Dictionary = {}          # ad -> {texture, hframes, fps, procedural}
var current := ""
var vel_y := 0.0                    # stretch efekti için dikey hız
var bounce_hz := 3.2
var squash_amount := 0.14

var _sprite := Sprite2D.new()
var _t := 0.0
var _frame_t := 0.0


func _init() -> void:
	_sprite.centered = true
	add_child(_sprite)


## set_def: sprite_set sözlüğü; placeholders: anim adı -> Texture2D (asset yoksa).
func setup(set_def: Dictionary, placeholders: Dictionary) -> void:
	display_height = float(set_def.get("display_height", display_height))
	anims.clear()
	var defs: Dictionary = set_def.get("anims", {})
	for anim_name in defs:
		var d: Dictionary = defs[anim_name]
		var tex := Game.load_texture(str(d.get("texture", "")))
		var hframes := int(d.get("hframes", 1))
		if tex == null:
			tex = placeholders.get(anim_name, placeholders.get("run"))
			hframes = 1
		anims[anim_name] = {
			"texture": tex,
			"hframes": maxi(1, hframes) if str(d.get("mode", "single")) == "sheet" else 1,
			"fps": float(d.get("fps", 0)),
			"procedural": str(d.get("procedural", "none")),
		}
	play("run")


func play(anim_name: String) -> void:
	if anim_name == current or not anims.has(anim_name):
		return
	current = anim_name
	var a: Dictionary = anims[anim_name]
	_sprite.texture = a.texture
	_sprite.hframes = a.hframes
	_sprite.frame = 0
	_frame_t = 0.0
	if a.texture:
		var fh := float(a.texture.get_height())
		_sprite.offset = Vector2(0, -fh / 2.0)


func _process(delta: float) -> void:
	_t += delta
	if current == "" or _sprite.texture == null:
		return
	var a: Dictionary = anims[current]
	if a.hframes > 1 and a.fps > 0.0:
		_frame_t += delta * a.fps
		_sprite.frame = int(_frame_t) % a.hframes
	var base := display_height / float(_sprite.texture.get_height())
	var sx := 1.0
	var sy := 1.0
	var hop := 0.0
	_sprite.rotation = 0.0
	_sprite.position = Vector2.ZERO
	match a.procedural:
		"bounce":
			var s := absf(sin(_t * bounce_hz * PI))
			hop = s * 3.0
			var land := pow(1.0 - s, 6.0)
			sy = 1.0 - squash_amount * land + 0.05 * s
			sx = 1.0 + squash_amount * land - 0.03 * s
		"stretch":
			var k := clampf(-vel_y / 900.0, -0.15, 0.22)
			sy = 1.0 + k
			sx = 1.0 - k * 0.6
		"squash":
			sy = 0.5 + 0.03 * sin(_t * 18.0)
			sx = 1.3
		"shake":
			_sprite.rotation = sin(_t * 40.0) * 0.12
			sy = 0.92
			sx = 1.06
	_sprite.scale = Vector2(base * sx, base * sy)
	_sprite.position.y = -hop
