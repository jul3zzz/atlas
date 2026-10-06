extends Node

func run(_args) -> void:
	if not Game.has_profile():
		Game.new_profile("Dbg", "france")
	var n: Control = Nav.goto_now("hub")
	for i in 5:
		await get_tree().process_frame
	print("viewport ", get_viewport().get_visible_rect())
	print("hub size ", n.size, " pos ", n.position, " anchors ", n.anchor_right, ",", n.anchor_bottom)
	for c in n.get_children():
		if c is Control:
			print("  child ", c.get_class(), " size ", c.size, " pos ", c.position, " anchors ", [c.anchor_left, c.anchor_top, c.anchor_right, c.anchor_bottom], " offs ", [c.offset_left, c.offset_top, c.offset_right, c.offset_bottom], " visible ", c.visible)
