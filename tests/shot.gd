extends Node
## Ekran görüntüsü alıcı (geliştirme aracı).
## godot --path . res://tests/shot.tscn -- res://scenes/game.tscn 240 out.png [seed]

var _frames := 0
var _target := 120
var _out := "shot.png"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var scene := args[0] if args.size() > 0 else "res://scenes/menu.tscn"
	_target = int(args[1]) if args.size() > 1 else 120
	_out = args[2] if args.size() > 2 else "shot.png"
	if args.size() > 3:
		Game.seed_code = args[3]
	var inst: Node = load(scene).instantiate()
	add_child.call_deferred(inst)
	if args.size() > 4:
		_jump_to.call_deferred(inst, float(args[4]))


## Hata ayıklama: dünyayı verilen metreye ışınla (tema görüntüleri için).
func _jump_to(inst: Node, m: float) -> void:
	await get_tree().process_frame
	var w: World = inst.world
	w.scroll = m * World.PX_PER_M
	w.obstacles.clear()
	w._next_x = w.scroll + 200.0
	w._generate_until(w.scroll + 600.0)


func _process(_d: float) -> void:
	_frames += 1
	if _frames == _target:
		var img := get_viewport().get_texture().get_image()
		img.save_png(_out)
		get_tree().quit()
