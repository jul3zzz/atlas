extends Node
## Navigation entre les écrans du jeu, avec fondu au noir.
## Exemple : Nav.goto("era", {"era": "e08"})

const SCREENS := {
	"title": "res://screens/title.gd",
	"profiles": "res://screens/profiles.gd",
	"hub": "res://screens/hub.gd",
	"era": "res://screens/era.gd",
	"history": "res://screens/history.gd",
	"quiz": "res://screens/quiz.gd",
	"battle": "res://battle/battle.gd",
	"battle_menu": "res://screens/battle_menu.gd",
	"workshop": "res://workshop/workshop.gd",
	"workshop_menu": "res://screens/workshop_menu.gd",
	"state": "res://screens/state_game.gd",
	"daily": "res://screens/daily.gd",
	"crates": "res://screens/crates.gd",
	"barracks": "res://screens/barracks.gd",
	"videos": "res://screens/videos.gd",
	"settings": "res://screens/settings.gd",
	"codex": "res://screens/codex.gd",
	"design": "res://workshop/design_office.gd",
}

var params: Dictionary = {}
var current_screen := ""
var _layer: CanvasLayer
var _fade: ColorRect
var _busy := false


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 90
	add_child(_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_fade)


func goto(screen: String, p: Dictionary = {}) -> void:
	if _busy or not SCREENS.has(screen):
		if not SCREENS.has(screen):
			push_error("Écran inconnu : " + screen)
		return
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.18)
	await tw.finished
	_swap(screen, p)
	var tw2 := create_tween()
	tw2.tween_property(_fade, "color:a", 0.0, 0.25)
	await tw2.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


## Changement immédiat (sans fondu) — utilisé au démarrage et par les tests.
func goto_now(screen: String, p: Dictionary = {}) -> Node:
	return _swap(screen, p)


func _swap(screen: String, p: Dictionary) -> Node:
	params = p
	current_screen = screen
	Engine.time_scale = 1.0
	get_tree().paused = false
	var tree := get_tree()
	var old := tree.current_scene
	var node: Node = load(SCREENS[screen]).new()
	node.name = screen.capitalize().replace(" ", "")
	tree.root.add_child(node)
	tree.current_scene = node
	if old:
		old.queue_free()
	return node
