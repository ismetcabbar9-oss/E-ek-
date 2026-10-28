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
	add_child.call_deferred(load(scene).instantiate())


func _process(_d: float) -> void:
	_frames += 1
	if _frames == _target:
		var img := get_viewport().get_texture().get_image()
		img.save_png(_out)
		get_tree().quit()
