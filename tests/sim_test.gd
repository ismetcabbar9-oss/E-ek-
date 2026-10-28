extends Node
## Başsız simülasyon testi: iki yapay zeka eşeği aynı seed'le uzun mesafe koşar.
## Çalıştır: godot --headless --path . res://tests/sim_test.tscn
## Kontroller: AI engelleri temizliyor mu, aynı seed aynı parkuru üretiyor mu.

func _ready() -> void:
	var ok := true
	for code in ["ESEK1", "ZEYNEP", "ISMET42"]:
		var a := _layout(code)
		var b := _layout(code)
		if a != b:
			print("FAIL: seed deterministik değil: ", code)
			ok = false
	if _layout("AAAAA") == _layout("BBBBB"):
		print("FAIL: farklı seed aynı parkur")
		ok = false
	var hits := 0
	for code in ["ESEK1", "ZEYNEP", "ISMET42", "KUZU"]:
		hits += _run_ai(code, 2200.0)
	print("AI çarpışma (4 x 2200 m): ", hits)
	if hits > 0:
		ok = false
		print("FAIL: AI çok çarpıyor")
	print("SONUÇ: ", "OK" if ok else "FAIL")
	get_tree().quit(0 if ok else 1)


func _layout(code: String) -> Array:
	var w := World.new()
	add_child(w)
	w.setup(Game.code_to_seed(code))
	var out: Array = []
	for i in 6000:
		w.advance(1.0 / 60.0)
		for o in w.obstacles:
			var key := "%d:%s:%d:%d" % [o.id, o.kind, int(o.x), int(o.w)]
			if out.is_empty() or out.find(key) == -1:
				out.append(key)
	w.queue_free()
	return out


func _run_ai(code: String, meters: float) -> int:
	var w := World.new()
	add_child(w)
	w.setup(Game.code_to_seed(code))
	var d := Donkey.new()
	add_child(d)
	var ai := AIController.new()
	ai.derp_chance = 0.0
	d.setup("ismet", ai, World.GROUND_Y)
	d.position.x = 104.0
	var hits := [0]
	d.crashed.connect(func(_dk, o): hits[0] += 1; print("  çarptı: ", o.kind, " @ ", w.meters(), " m"))
	var dt := 1.0 / 60.0
	while w.meters() < meters:
		w.advance(dt)
		d.step(dt, w)
		var o := w.check_collision(d)
		if not o.is_empty():
			d.take_hit(o)
	return hits[0]
