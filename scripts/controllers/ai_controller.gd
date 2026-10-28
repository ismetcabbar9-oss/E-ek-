class_name AIController
extends PlayerController
## Partner eşek: önündeki engele bakıp kendi zıplar / eğilir.
## Ara sıra (derp_chance) bilerek beceriksizlik yapar, komiklik olsun diye.
## Kendi RNG'sini kullanır; parkurun seed'ini etkilemez.

var derp_chance := 0.03
var reaction_jitter := 0.03       # saniye cinsinden zamanlama sapması

var _rng := RandomNumberGenerator.new()
var _jump := false
var _duck := false
var _decided: Dictionary = {}      # engel id -> {derp, jitter}


func _ready() -> void:
	_rng.randomize()


func update(_delta: float, world: Node) -> void:
	_jump = false
	_duck = false
	if donkey == null or world == null:
		return
	var speed: float = world.speed
	var front: float = donkey.position.x + donkey.hit_w / 2.0
	var back: float = donkey.position.x - donkey.hit_w / 2.0
	for o in world.obstacles_on_screen():
		var r: Rect2 = world.screen_rect(o)
		if r.end.x < back:
			continue
		var plan: Dictionary = _plan_for(o)
		if plan.derp:
			break
		var dist := r.position.x - front
		match o.kind:
			"low", "pit":
				# Zıplamanın en yüksek noktası engelin ortasına denk gelsin.
				var half_air := -Donkey.JUMP_V / Donkey.GRAVITY
				var lead: float = speed * (half_air + plan.jitter) - donkey.hit_w / 2.0 - r.size.x / 2.0
				if dist <= lead and dist > -4.0:
					_jump = true
			"air":
				if dist <= speed * 0.25 and r.end.x > back - 2.0:
					_duck = true
		break


func _plan_for(o: Dictionary) -> Dictionary:
	if not _decided.has(o.id):
		_decided[o.id] = {
			"derp": _rng.randf() < derp_chance,
			"jitter": _rng.randf_range(-reaction_jitter, reaction_jitter),
		}
		if _decided.size() > 64:
			_decided.erase(_decided.keys()[0])
	return _decided[o.id]


func wants_jump() -> bool:
	return _jump


func wants_duck() -> bool:
	return _duck
