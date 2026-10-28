class_name HumanController
extends PlayerController
## Dokunmatik: ekranın üst kısmına dokun = zıpla, alt üçte birine basılı tut = eğil.
## Masaüstünde test için: Boşluk/Yukarı/W = zıpla, Aşağı/S = eğil (fare de dokunma sayılır).

const JUMP_BUFFER := 0.15
const VIEW_H := 180.0

var _jump_buffer := 0.0
var _duck_touches: Dictionary = {}   # dokunma index -> true
var _key_jump_was := false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var p: Vector2 = _to_view(event.position)
		if event.pressed:
			if p.y >= VIEW_H * 2.0 / 3.0:
				_duck_touches[event.index] = true
			else:
				_jump_buffer = JUMP_BUFFER
		else:
			_duck_touches.erase(event.index)
	elif event is InputEventScreenDrag:
		# Parmak alt bölgeden çıkarsa eğilme biter.
		var p2: Vector2 = _to_view(event.position)
		if _duck_touches.has(event.index) and p2.y < VIEW_H * 2.0 / 3.0 - 8.0:
			_duck_touches.erase(event.index)


func _to_view(screen_pos: Vector2) -> Vector2:
	# Olay konumunu 320x180 sanal görünüme çevir.
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos


func update(delta: float, _world: Node) -> void:
	_jump_buffer = maxf(0.0, _jump_buffer - delta)
	var key_jump := Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W)
	if key_jump and not _key_jump_was:
		_jump_buffer = JUMP_BUFFER
	_key_jump_was = key_jump


func wants_jump() -> bool:
	if _jump_buffer > 0.0:
		_jump_buffer = 0.0
		return true
	return false


func wants_duck() -> bool:
	return not _duck_touches.is_empty() or Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S)


func is_human() -> bool:
	return true
