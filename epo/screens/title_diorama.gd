extends Control
## Diorama 3D de l'écran titre : un soldat de chaque époque, en demi-cercle.

const LINEUP := ["legionnaire", "man_at_arms", "musketeer", "grenadier", "chassepot_inf", "poilu", "kieffer_commando", "soviet_ak", "french_para", "modern_inf"]

var _soldiers: Array = []
var _pivot: Node3D
var _t := 0.0
var _next_attack := 1.5


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.set_anchors_preset(Control.PRESET_FULL_RECT)
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(svc)
	var vp := SubViewport.new()
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	svc.add_child(vp)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.72, 0.62)
	e.ambient_light_energy = 0.6
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -50, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	vp.add_child(sun)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 140, 0)
	rim.light_energy = 0.5
	rim.light_color = Color(1.0, 0.8, 0.5)
	vp.add_child(rim)

	_pivot = Node3D.new()
	vp.add_child(_pivot)
	var base := Models.cyl(7.6, 7.9, 0.4, Models.mat(Color("2a3220"), 0.95), Vector3(0, -0.2, 0), Vector3.ZERO, 48)
	_pivot.add_child(base)
	_pivot.add_child(Models.torus(7.55, 7.95, Models.metal_mat(Color("8a6f17")), Vector3(0, 0.0, 0)))
	var n := LINEUP.size()
	for i in n:
		var id: String = LINEUP[i]
		if not Content.units.has(id):
			continue
		var m := UnitFactory.build_model(Content.units[id], UI.GOLD)
		var ang := lerpf(-1.25, 1.25, float(i) / float(n - 1))
		m.position = Vector3(sin(ang) * 5.2, 0, cos(ang) * 5.2 - 2.0)
		m.rotation.y = ang
		_pivot.add_child(m)
		_soldiers.append(m)
		# Petit socle avec le numéro d'époque.
		var plate := Models.cyl(0.62, 0.66, 0.08, Models.mat(Color("1a1f13"), 0.9), m.position + Vector3(0, 0.0, 0), Vector3.ZERO, 20)
		_pivot.add_child(plate)

	var cam := Camera3D.new()
	cam.fov = 38.0
	vp.add_child(cam)
	cam.position = Vector3(-3.2, 4.2, 15.5)
	cam.look_at(Vector3(-3.6, 1.1, 0))
	cam.current = true


func _process(delta: float) -> void:
	_t += delta
	_pivot.rotation.y = sin(_t * 0.15) * 0.25
	for s in _soldiers:
		if s is SoldierModel:
			s.animate(delta, 0.0, sin(_t * 0.5 + s.position.x) > 0.6)
	_next_attack -= delta
	if _next_attack <= 0.0 and not _soldiers.is_empty():
		_next_attack = randf_range(1.2, 2.5)
		var s = _soldiers[randi() % _soldiers.size()]
		if s is SoldierModel:
			s.play_attack(0.4)
