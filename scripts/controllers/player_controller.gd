class_name PlayerController
extends Node
## Bir eşeği kim yönetiyorsa (dokunmatik, yapay zeka, ileride online oyuncu)
## bu arayüzü uygular. Eşek her fizik adımında önce update()'i çağırır,
## sonra wants_jump() / wants_duck() ile niyeti okur.
##
## Online için: RemoteController bu sınıfı genişletip ağdan gelen
## {jump, duck} durumlarını aynı fonksiyonlardan döndürmesi yeterli.

## Kontrol ettiği eşek (Donkey).
var donkey: Node2D


## Her fizik adımında bir kez. world: World düğümü (engelleri okumak için).
func update(_delta: float, _world: Node) -> void:
	pass


## Bu adımda zıplama isteği var mı? (true dönerse istek tüketilmiş sayılır)
func wants_jump() -> bool:
	return false


## Eğilme tuşu basılı tutuluyor mu?
func wants_duck() -> bool:
	return false


## Kontrolcü insan mı? (çarpışmalar çiftçiyi yaklaştırır mı vb.)
func is_human() -> bool:
	return false
