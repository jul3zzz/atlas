class_name VehicleModel
extends Node3D
## Véhicules et pièces d'artillerie low-poly. L'avant est -Z.
## Types : chariot, catapult, trebuchet, bombard, cannon, field_gun, mg_nest,
##         ft17, medium_tank, t55, mbt, helicopter, drone

var kind := ""
var turret: Node3D
var barrel: Node3D
var muzzle: Marker3D
var arm: Node3D
var rotor: Node3D
var tail_rotor: Node3D
var wheels: Array[Node3D] = []
var crew: Array[SoldierModel] = []
var horses: Array[HorseModel] = []
var hover_height := 0.0
var _barrel_rest := Vector3.ZERO
var _t := 0.0
var _arm_anim := -1.0


func build(k: String, c: Color, accent: Color, crew_cfg: Dictionary = {}) -> void:
	kind = k
	var m := Models.mat(c, 0.75, 0.15)
	var dark := Models.mat(c.darkened(0.45), 0.8, 0.1)
	var steel := Models.metal_mat(Color("4a4d50"))
	var black := Models.mat(Color("1b1c1a"), 0.7)
	var wood := Models.mat(Color("6b4423"), 0.85)
	var bronze := Models.metal_mat(Color("a8782f"))
	var acc := Models.mat(accent, 0.6)
	muzzle = Marker3D.new()
	match k:
		"chariot":
			add_child(Models.box(Vector3(1.1, 0.08, 0.85), wood, Vector3(0, 0.85, 0.2)))
			add_child(Models.box(Vector3(1.1, 0.5, 0.05), m, Vector3(0, 1.1, -0.2)))
			add_child(Models.box(Vector3(0.05, 0.4, 0.8), m, Vector3(0.53, 1.05, 0.2)))
			add_child(Models.box(Vector3(0.05, 0.4, 0.8), m, Vector3(-0.53, 1.05, 0.2)))
			add_child(Models.cyl(0.04, 0.04, 1.6, wood, Vector3(0, 0.6, 0.4), Vector3(0, 0, PI / 2)))
			add_child(Models.cyl(0.035, 0.035, 2.2, wood, Vector3(0, 0.75, -1.0), Vector3(PI / 2 - 0.08, 0, 0)))
			for sx in [-1.0, 1.0]:
				var w := _wheel(0.55, 0.06, wood, Vector3(0.72 * sx, 0.6, 0.4))
				w.add_child(Models.torus(0.47, 0.55, acc, Vector3.ZERO, Vector3(0, 0, PI / 2)))
			for sx in [-1.0, 1.0]:
				var h := Models.horse(Color("e8dcc4") if sx < 0 else Color("6b4a2a"))
				h.position = Vector3(0.42 * sx, 0, -2.0)
				h.scale = Vector3.ONE * 0.85
				add_child(h)
				horses.append(h)
			_add_crew(crew_cfg, [Vector3(-0.25, 0.85, 0.3), Vector3(0.25, 0.85, 0.2)], ["", "bow"])
			muzzle.position = Vector3(0.25, 2.2, 0.0)
		"catapult":
			add_child(Models.box(Vector3(1.4, 0.25, 2.6), wood, Vector3(0, 0.45, 0)))
			for sx in [-1.0, 1.0]:
				_wheel(0.4, 0.1, wood, Vector3(0.78 * sx, 0.4, 0.8))
				_wheel(0.4, 0.1, wood, Vector3(0.78 * sx, 0.4, -0.8))
				add_child(Models.box(Vector3(0.15, 1.2, 0.15), wood, Vector3(0.55 * sx, 1.1, -0.3), Vector3(0.3, 0, 0)))
			add_child(Models.box(Vector3(1.3, 0.15, 0.15), wood, Vector3(0, 1.6, -0.55)))
			arm = Node3D.new()
			arm.position = Vector3(0, 0.7, 0.6)
			arm.rotation.x = -1.1
			add_child(arm)
			arm.add_child(Models.box(Vector3(0.14, 0.14, 2.4), wood, Vector3(0, 0, -1.1)))
			arm.add_child(Models.sphere(0.22, Models.mat(Color("6d6a62")), Vector3(0, 0.15, -2.25)))
			muzzle.position = Vector3(0, 2.5, -1.2)
			_add_crew(crew_cfg, [Vector3(1.3, 0, 0.5), Vector3(-1.3, 0, 0.8)], ["", ""])
		"trebuchet":
			for sx in [-1.0, 1.0]:
				add_child(Models.box(Vector3(0.2, 4.6, 0.2), wood, Vector3(0.8 * sx, 2.2, -0.6), Vector3(-0.25, 0, 0)))
				add_child(Models.box(Vector3(0.2, 4.6, 0.2), wood, Vector3(0.8 * sx, 2.2, 0.6), Vector3(0.25, 0, 0)))
				add_child(Models.box(Vector3(0.25, 0.25, 3.4), wood, Vector3(0.8 * sx, 0.12, 0)))
			add_child(Models.cyl(0.1, 0.1, 1.9, wood, Vector3(0, 4.3, 0), Vector3(0, 0, PI / 2)))
			arm = Node3D.new()
			arm.position = Vector3(0, 4.3, 0)
			arm.rotation.x = 0.95
			add_child(arm)
			arm.add_child(Models.box(Vector3(0.22, 0.22, 7.0), wood, Vector3(0, 0, -1.8)))
			arm.add_child(Models.box(Vector3(1.0, 1.1, 1.0), Models.mat(Color("57534a")), Vector3(0, -0.6, 1.6)))
			arm.add_child(Models.sphere(0.3, Models.mat(Color("8a8579")), Vector3(0, 0, -5.2)))
			muzzle.position = Vector3(0, 7.5, -2.0)
			_add_crew(crew_cfg, [Vector3(1.6, 0, 1.2), Vector3(-1.6, 0, 1.0), Vector3(1.5, 0, -1.5)], ["", "", ""])
		"bombard":
			add_child(Models.box(Vector3(1.3, 0.5, 3.4), wood, Vector3(0, 0.25, 0.2)))
			barrel = Node3D.new()
			barrel.position = Vector3(0, 0.9, 0)
			add_child(barrel)
			barrel.add_child(Models.cyl(0.42, 0.48, 3.2, bronze, Vector3(0, 0, -0.2), Vector3(PI / 2 - 0.08, 0, 0), 14))
			barrel.add_child(Models.torus(0.4, 0.52, bronze, Vector3(0, 0, -1.6), Vector3(PI / 2, 0, 0)))
			muzzle.position = Vector3(0, 0.0, -1.9)
			barrel.add_child(muzzle)
			_add_crew(crew_cfg, [Vector3(1.2, 0, 0.8), Vector3(-1.2, 0, 1.0)], ["", "torch"])
		"cannon":
			for sx in [-1.0, 1.0]:
				_wheel(0.65, 0.09, wood, Vector3(0.55 * sx, 0.65, 0))
			add_child(Models.cyl(0.05, 0.05, 1.25, steel, Vector3(0, 0.65, 0), Vector3(0, 0, PI / 2)))
			add_child(Models.box(Vector3(0.35, 0.22, 2.2), wood, Vector3(0, 0.5, 1.0), Vector3(-0.3, 0, 0)))
			barrel = Node3D.new()
			barrel.position = Vector3(0, 0.95, 0)
			add_child(barrel)
			barrel.add_child(Models.cyl(0.11, 0.17, 1.9, bronze, Vector3(0, 0.0, -0.4), Vector3(PI / 2, 0, 0), 12))
			barrel.add_child(Models.sphere(0.13, bronze, Vector3(0, 0, 0.6)))
			muzzle.position = Vector3(0, 0.0, -1.4)
			barrel.add_child(muzzle)
			_add_crew(crew_cfg, [Vector3(1.1, 0, 0.3), Vector3(-1.0, 0, 1.4)], ["", ""])
		"field_gun":
			for sx in [-1.0, 1.0]:
				_wheel(0.6, 0.08, wood, Vector3(0.6 * sx, 0.6, 0))
			add_child(Models.box(Vector3(1.5, 1.1, 0.06), m, Vector3(0, 1.0, -0.25)))
			add_child(Models.box(Vector3(0.3, 0.2, 2.4), m, Vector3(0, 0.45, 1.1), Vector3(-0.25, 0, 0)))
			barrel = Node3D.new()
			barrel.position = Vector3(0, 0.95, 0)
			add_child(barrel)
			barrel.add_child(Models.cyl(0.06, 0.08, 2.3, steel, Vector3(0, 0, -0.7), Vector3(PI / 2, 0, 0), 10))
			barrel.add_child(Models.box(Vector3(0.28, 0.25, 0.9), m, Vector3(0, -0.05, 0.1)))
			muzzle.position = Vector3(0, 0, -1.9)
			barrel.add_child(muzzle)
			_add_crew(crew_cfg, [Vector3(0.9, 0, 0.8), Vector3(-0.9, 0, 0.9)], ["", ""])
		"mg_nest":
			var sand := Models.mat(Color("8f8466"), 0.95)
			for i in 9:
				var ang := -PI * 0.75 + i * PI * 1.5 / 8.0
				var bag := Models.capsule(0.22, 0.75, sand, Vector3(sin(ang) * 1.3, 0.22, -cos(ang) * 1.3), Vector3(0, -ang, PI / 2))
				add_child(bag)
				var bag2 := Models.capsule(0.2, 0.7, sand, Vector3(sin(ang) * 1.3, 0.6, -cos(ang) * 1.3), Vector3(0, -ang + 0.15, PI / 2))
				add_child(bag2)
			turret = Node3D.new()
			turret.position = Vector3(0, 0.9, -0.5)
			add_child(turret)
			barrel = Node3D.new()
			turret.add_child(barrel)
			barrel.add_child(Models.box(Vector3(0.14, 0.16, 0.7), black, Vector3(0, 0, 0.1)))
			barrel.add_child(Models.cyl(0.05, 0.05, 0.9, black, Vector3(0, 0.02, -0.65), Vector3(PI / 2, 0, 0)))
			barrel.add_child(Models.box(Vector3(0.06, 0.4, 0.06), black, Vector3(0, -0.25, -0.1)))
			muzzle.position = Vector3(0, 0.02, -1.1)
			barrel.add_child(muzzle)
			_add_crew(crew_cfg, [Vector3(0.3, 0, 0.4), Vector3(-0.5, 0, 0.5)], ["", ""])
		"ft17":
			_tracks(0.32, 0.95, 3.1, 0.62, dark)
			add_child(Models.box(Vector3(0.95, 1.0, 2.3), m, Vector3(0, 1.0, 0.05)))
			add_child(Models.box(Vector3(0.95, 0.5, 0.6), m, Vector3(0, 0.75, 1.45), Vector3(0.5, 0, 0)))
			add_child(Models.box(Vector3(0.6, 0.12, 1.0), dark, Vector3(0, 0.55, 2.0), Vector3(0.3, 0, 0)))
			turret = Node3D.new()
			turret.position = Vector3(0, 1.5, -0.25)
			add_child(turret)
			turret.add_child(Models.cyl(0.42, 0.46, 0.6, m, Vector3(0, 0.3, 0), Vector3.ZERO, 8))
			turret.add_child(Models.cyl(0.0, 0.32, 0.15, m, Vector3(0, 0.67, 0), Vector3.ZERO, 8))
			barrel = Node3D.new()
			barrel.position = Vector3(0, 0.32, -0.42)
			turret.add_child(barrel)
			barrel.add_child(Models.cyl(0.06, 0.07, 0.55, steel, Vector3(0, 0, -0.2), Vector3(PI / 2, 0, 0)))
			muzzle.position = Vector3(0, 0, -0.5)
			barrel.add_child(muzzle)
		"medium_tank":
			_tracks(0.5, 1.0, 4.8, 1.15, dark)
			add_child(Models.box(Vector3(1.9, 0.9, 4.4), m, Vector3(0, 1.15, 0)))
			add_child(Models.box(Vector3(1.9, 0.6, 1.0), m, Vector3(0, 1.05, -2.3), Vector3(-0.7, 0, 0)))
			turret = Node3D.new()
			turret.position = Vector3(0, 1.6, -0.2)
			add_child(turret)
			turret.add_child(Models.cyl(0.85, 0.95, 0.75, m, Vector3(0, 0.38, 0.1), Vector3.ZERO, 12))
			turret.add_child(Models.cyl(0.3, 0.3, 0.2, dark, Vector3(0.3, 0.85, 0.3), Vector3.ZERO, 10))
			turret.add_child(Models.box(Vector3(0.9, 0.06, 0.06), acc, Vector3(0, 0.6, 0.95)))
			barrel = Node3D.new()
			barrel.position = Vector3(0, 0.4, -0.85)
			turret.add_child(barrel)
			barrel.add_child(Models.box(Vector3(0.45, 0.4, 0.4), m, Vector3(0, 0, 0)))
			barrel.add_child(Models.cyl(0.07, 0.08, 2.6, steel, Vector3(0, 0, -1.4), Vector3(PI / 2, 0, 0)))
			muzzle.position = Vector3(0, 0, -2.7)
			barrel.add_child(muzzle)
		"t55":
			_tracks(0.55, 0.85, 5.2, 1.3, dark)
			add_child(Models.box(Vector3(2.1, 0.75, 5.0), m, Vector3(0, 1.0, 0)))
			add_child(Models.box(Vector3(2.1, 0.5, 1.0), m, Vector3(0, 0.95, -2.6), Vector3(-0.9, 0, 0)))
			for i in 2:
				add_child(Models.cyl(0.25, 0.25, 1.2, dark, Vector3(0.6 - i * 1.2, 1.6, 2.2), Vector3(0, 0, PI / 2)))
			turret = Node3D.new()
			turret.position = Vector3(0, 1.35, -0.6)
			add_child(turret)
			turret.add_child(Models.sphere(1.1, m, Vector3(0, 0, 0), Vector3(1.0, 0.62, 1.15), true))
			turret.add_child(Models.cyl(0.25, 0.25, 0.25, dark, Vector3(-0.35, 0.7, 0.2)))
			turret.add_child(Models.sphere(0.12, Models.mat(Color("c0262d"), 0.5), Vector3(0.75, 0.35, -0.4)))
			barrel = Node3D.new()
			barrel.position = Vector3(0, 0.35, -1.0)
			turret.add_child(barrel)
			barrel.add_child(Models.cyl(0.07, 0.08, 3.4, steel, Vector3(0, 0, -1.7), Vector3(PI / 2, 0, 0)))
			barrel.add_child(Models.cyl(0.12, 0.12, 0.35, steel, Vector3(0, 0, -2.5), Vector3(PI / 2, 0, 0)))
			muzzle.position = Vector3(0, 0, -3.4)
			barrel.add_child(muzzle)
		"mbt":
			_tracks(0.6, 0.95, 6.2, 1.55, dark)
			add_child(Models.box(Vector3(2.5, 0.9, 6.0), m, Vector3(0, 1.15, 0)))
			add_child(Models.box(Vector3(2.5, 0.5, 1.2), m, Vector3(0, 1.05, -3.1), Vector3(-1.0, 0, 0)))
			turret = Node3D.new()
			turret.position = Vector3(0, 1.62, 0.1)
			add_child(turret)
			turret.add_child(Models.box(Vector3(2.4, 0.75, 3.0), m, Vector3(0, 0.38, 0.2)))
			turret.add_child(Models.prism(Vector3(2.4, 0.75, 0.9), m, Vector3(0, 0.38, -1.5), Vector3(-PI / 2, 0, 0)))
			turret.add_child(Models.box(Vector3(0.45, 0.35, 0.45), dark, Vector3(0.7, 0.92, 0.3)))
			turret.add_child(Models.box(Vector3(2.2, 0.5, 0.6), dark, Vector3(0, 0.35, 1.95)))
			barrel = Node3D.new()
			barrel.position = Vector3(0, 0.4, -1.6)
			turret.add_child(barrel)
			barrel.add_child(Models.cyl(0.08, 0.09, 4.4, steel, Vector3(0, 0, -2.1), Vector3(PI / 2, 0, 0)))
			muzzle.position = Vector3(0, 0, -4.3)
			barrel.add_child(muzzle)
		"helicopter":
			hover_height = 7.0
			var body := Node3D.new()
			add_child(body)
			body.add_child(Models.capsule(0.85, 3.6, m, Vector3(0, 0, 0), Vector3(PI / 2, 0, 0), Vector3(0.9, 1.05, 1)))
			body.add_child(Models.sphere(0.8, Models.mat(Color(0.5, 0.75, 0.8, 0.7), 0.1, 0.2), Vector3(0, 0.15, -1.45), Vector3(0.95, 0.85, 0.8)))
			body.add_child(Models.cyl(0.18, 0.32, 4.2, m, Vector3(0, 0.35, 3.6), Vector3(PI / 2, 0, 0)))
			body.add_child(Models.box(Vector3(0.08, 1.0, 0.6), m, Vector3(0, 0.8, 5.5)))
			for sx in [-1.0, 1.0]:
				body.add_child(Models.cyl(0.05, 0.05, 3.0, black, Vector3(0.75 * sx, -1.15, 0), Vector3(PI / 2, 0, 0)))
				body.add_child(Models.box(Vector3(0.05, 0.4, 0.05), black, Vector3(0.7 * sx, -0.95, -0.7)))
				body.add_child(Models.box(Vector3(0.05, 0.4, 0.05), black, Vector3(0.7 * sx, -0.95, 0.7)))
			body.add_child(Models.box(Vector3(0.9, 0.08, 0.8), acc, Vector3(0, 0.6, 0.5)))
			rotor = Node3D.new()
			rotor.position = Vector3(0, 1.2, 0)
			body.add_child(rotor)
			rotor.add_child(Models.cyl(0.12, 0.12, 0.35, black, Vector3(0, -0.15, 0)))
			rotor.add_child(Models.box(Vector3(12.0, 0.04, 0.4), black))
			tail_rotor = Node3D.new()
			tail_rotor.position = Vector3(0.12, 0.9, 5.6)
			body.add_child(tail_rotor)
			tail_rotor.add_child(Models.box(Vector3(0.04, 1.8, 0.2), black))
			turret = Node3D.new()
			turret.position = Vector3(0.9, -0.2, -0.3)
			body.add_child(turret)
			barrel = Node3D.new()
			turret.add_child(barrel)
			barrel.add_child(Models.cyl(0.05, 0.05, 0.9, black, Vector3(0, 0, -0.3), Vector3(PI / 2, 0, 0)))
			muzzle.position = Vector3(0, 0, -0.8)
			barrel.add_child(muzzle)
		"drone":
			hover_height = 4.5
			var frame := Node3D.new()
			add_child(frame)
			frame.add_child(Models.box(Vector3(0.22, 0.08, 0.3), black))
			frame.add_child(Models.box(Vector3(0.12, 0.08, 0.1), Models.mat(Color("ff7a1a"), 0.5, 0.0, 0.6), Vector3(0, 0.07, -0.1)))
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					var arm_mesh := Models.box(Vector3(0.05, 0.03, 0.42), black, Vector3(0.14 * sx, 0, 0.14 * sz), Vector3(0, sx * sz * PI / 4, 0))
					frame.add_child(arm_mesh)
					var r := Node3D.new()
					r.position = Vector3(0.28 * sx, 0.06, 0.28 * sz)
					frame.add_child(r)
					r.add_child(Models.cyl(0.04, 0.04, 0.06, Models.metal_mat(Color("888888"))))
					r.add_child(Models.box(Vector3(0.36, 0.01, 0.05), Models.mat(Color(0.2, 0.2, 0.2, 0.8))))
					wheels.append(r)
			frame.add_child(Models.cyl(0.06, 0.06, 0.25, Models.mat(Color("4b5a32")), Vector3(0, -0.08, 0.0), Vector3(PI / 2, 0, 0)))
			frame.scale = Vector3.ONE * 1.4
			muzzle.position = Vector3(0, 0, -0.3)
	if muzzle.get_parent() == null:
		add_child(muzzle)
	if barrel:
		_barrel_rest = barrel.position


func _wheel(r: float, w: float, material: Material, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.add_child(Models.cyl(r, r, w, material, Vector3.ZERO, Vector3(0, 0, PI / 2), 14))
	n.add_child(Models.box(Vector3(w * 1.2, r * 1.8, 0.06), material))
	n.add_child(Models.box(Vector3(w * 1.2, 0.06, r * 1.8), material))
	add_child(n)
	wheels.append(n)
	return n


func _tracks(w: float, h: float, length: float, x: float, material: Material) -> void:
	for sx in [-1.0, 1.0]:
		var t := Node3D.new()
		t.position = Vector3(x * sx, h * 0.5, 0)
		add_child(t)
		t.add_child(Models.box(Vector3(w, h * 0.7, length - h * 0.7), material))
		t.add_child(Models.cyl(h * 0.35, h * 0.35, w, material, Vector3(0, 0, -(length - h * 0.7) / 2), Vector3(0, 0, PI / 2)))
		t.add_child(Models.cyl(h * 0.35, h * 0.35, w, material, Vector3(0, 0, (length - h * 0.7) / 2), Vector3(0, 0, PI / 2)))
		for i in 5:
			var wheel := Models.cyl(h * 0.25, h * 0.25, w + 0.04, Models.mat(Color("2a2a26")), Vector3(0, -h * 0.12, -length * 0.35 + i * length * 0.175), Vector3(0, 0, PI / 2))
			t.add_child(wheel)


func _add_crew(crew_cfg: Dictionary, positions: Array, weapons: Array) -> void:
	if crew_cfg.is_empty():
		return
	for i in positions.size():
		var c := crew_cfg.duplicate()
		c["weapon"] = weapons[i] if i < weapons.size() else ""
		c["shield"] = ""
		c["mount"] = ""
		var s := Models.soldier(c)
		s.position = positions[i]
		add_child(s)
		crew.append(s)


func animate(delta: float, speed: float, aiming := false) -> void:
	_t += delta
	for w in wheels:
		if kind == "drone":
			w.rotation.y += delta * 40.0
		else:
			w.rotation.x -= delta * speed * 1.6
	for h in horses:
		h.animate(delta, speed)
	for s in crew:
		s.animate(delta, speed, aiming)
	if rotor:
		rotor.rotation.y += delta * 22.0
	if tail_rotor:
		tail_rotor.rotation.x += delta * 30.0
	if hover_height > 0.0:
		position.y = hover_height + sin(_t * 1.7) * 0.25
	if barrel:
		barrel.position = barrel.position.lerp(_barrel_rest, delta * 6.0)
	if arm and _arm_anim >= 0.0:
		_arm_anim += delta
		var rest := -1.1 if kind == "catapult" else 0.95
		var fired := 0.9 if kind == "catapult" else -1.4
		if _arm_anim < 0.35:
			arm.rotation.x = lerpf(rest, fired, ease(_arm_anim / 0.35, 0.3))
		elif _arm_anim < 2.0:
			arm.rotation.x = lerpf(fired, rest, (_arm_anim - 0.35) / 1.65)
		else:
			arm.rotation.x = rest
			_arm_anim = -1.0


func fire_anim() -> void:
	if barrel:
		barrel.position = _barrel_rest + Vector3(0, 0, 0.35)
	if arm:
		_arm_anim = 0.0
	for s in crew:
		s.play_attack(0.4)
