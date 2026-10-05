extends Node
## Point d'entrée : affiche l'écran titre.


func _ready() -> void:
	Nav.call_deferred("goto_now", "title")
