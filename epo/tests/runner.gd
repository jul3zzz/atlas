extends Node
## Lanceur de tests / captures d'écran.
## godot --path . res://tests/runner.tscn -- <commande> [arguments]
##   shot <écran> <fichier.png> [clé=valeur ...]   capture d'un écran
##   models <fichier.png>                         galerie des modèles 3D
##   smoke                                         ouvre tous les écrans

var args: PackedStringArray


func _ready() -> void:
	# Le lanceur ne doit pas être remplacé par les écrans qu'il ouvre.
	get_tree().current_scene = null
	args = OS.get_cmdline_user_args()
	if args.is_empty():
		args = PackedStringArray(["smoke"])
	await get_tree().process_frame
	match args[0]:
		"shot":
			await _shot()
		"models":
			await _models()
		"smoke":
			await _smoke()
		_:
			var script := load("res://tests/%s.gd" % args[0])
			var t = script.new()
			add_child(t)
			await t.run(args)
	get_tree().quit()


func _params(from: int) -> Dictionary:
	var p := {}
	for i in range(from, args.size()):
		var kv := args[i].split("=", true, 1)
		if kv.size() == 2:
			var v: Variant = kv[1]
			if kv[1] == "true":
				v = true
			elif kv[1] == "false":
				v = false
			elif kv[1].is_valid_int():
				v = int(kv[1])
			p[kv[0]] = v
	return p


func _ensure_profile() -> void:
	if not Game.has_profile():
		Game.new_profile("Testeur", "france")


func _wait(frames: int) -> void:
	for i in frames:
		await get_tree().process_frame


func _save(path: String) -> void:
	if DisplayServer.get_name() == "headless":
		print("(headless : pas de capture) ", path)
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("CAPTURE ", path, " ", img.get_size())


func _shot() -> void:
	_ensure_profile()
	var p := _params(3)
	var frames := int(p.get("frames", 30))
	var node := Nav.goto_now(args[1], p)
	await _wait(frames)
	if p.has("action") and node.has_method("test_action"):
		await node.test_action(String(p.action))
		await _wait(int(p.get("after", 30)))
	await _save(args[2])


func _models() -> void:
	var root := Node3D.new()
	get_tree().root.add_child(root)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("6f8aa0")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.shadow_enabled = true
	root.add_child(sun)
	var ground := Models.box(Vector3(80, 0.1, 40), Models.mat(Color("6b7a45")), Vector3(0, -0.05, 0))
	root.add_child(ground)
	var units: Array = Content.units.values()
	var x := -float(min(units.size(), 14)) * 1.2
	var row := 0
	var i := 0
	for u in units:
		var node: Node3D = UnitFactory.build_model(u, Color("3d7fd1"))
		node.position = Vector3(x + (i % 14) * 2.4, 0, -row * 4.0)
		root.add_child(node)
		i += 1
		if i % 14 == 0:
			row += 1
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.position = Vector3(0, 6, 12)
	cam.look_at(Vector3(0, 1, -4))
	cam.fov = 60
	await _wait(10)
	await _save(args[1])


func _smoke() -> void:
	_ensure_profile()
	var errors := 0
	for screen in Nav.SCREENS:
		var p := {"era": "e08"}
		if screen == "battle":
			p = {"battle": Content.battles[0].id if Content.battles.size() else ""}
		print("--- ", screen)
		var node := Nav.goto_now(screen, p)
		await _wait(8)
		if not is_instance_valid(node):
			errors += 1
	print("SMOKE DONE errors=", errors)
