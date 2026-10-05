class_name WeaponModel
extends Node3D
## Arme (ou machine) construite pièce par pièce à partir de son fichier data/weapons/*.json.
## Chaque pièce est un Node3D avec ses formes, une zone cliquable et une position « éclatée ».

const MATERIALS := {
	"metal": ["3a3d40", 0.4, 0.8],
	"steel": ["9aa0a6", 0.3, 0.85],
	"blued": ["23272b", 0.35, 0.8],
	"wood": ["6a3e1f", 0.75, 0.0],
	"light_wood": ["9a6a3a", 0.75, 0.0],
	"brass": ["c9a33a", 0.3, 0.9],
	"bronze": ["a8782f", 0.35, 0.85],
	"black": ["1d1e1c", 0.6, 0.1],
	"polymer": ["2b2c2a", 0.7, 0.0],
	"rope": ["c9b48a", 0.95, 0.0],
	"leather": ["5a3a22", 0.8, 0.0],
	"stone": ["8a8579", 0.95, 0.0],
	"paint": ["55603d", 0.7, 0.1],
	"red": ["a3262a", 0.6, 0.0],
	"glass": ["9fd0e0", 0.1, 0.2],
	"copper": ["b8733a", 0.35, 0.85],
	"green_pcb": ["2f6a3a", 0.5, 0.1],
}

var data: Dictionary
var parts: Dictionary = {}        # id -> Node3D
var part_data: Dictionary = {}    # id -> Dictionary
var home: Dictionary = {}         # id -> Transform3D d'origine
var removed: Dictionary = {}      # id -> bool (démontage)
var explode_amount := 0.0
var _hl_mat: StandardMaterial3D
var _hovered := ""


func build(d: Dictionary) -> void:
	data = d
	_hl_mat = StandardMaterial3D.new()
	_hl_mat.albedo_color = Color(1.0, 0.8, 0.2, 0.35)
	_hl_mat.emission_enabled = true
	_hl_mat.emission = Color(1.0, 0.7, 0.1)
	_hl_mat.emission_energy_multiplier = 0.8
	_hl_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_hl_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for p in d.get("parts", []):
		var node := Node3D.new()
		node.name = String(p.id)
		node.position = _v3(p.get("pos", [0, 0, 0]))
		node.rotation_degrees = _v3(p.get("rot", [0, 0, 0]))
		add_child(node)
		parts[p.id] = node
		part_data[p.id] = p
		home[p.id] = node.transform
		var body := StaticBody3D.new()
		body.collision_layer = 8
		body.set_meta("part", p.id)
		node.add_child(body)
		for s in p.get("shapes", []):
			var mesh := _shape_mesh(s)
			node.add_child(mesh)
			var cs := _shape_collision(s)
			if cs:
				body.add_child(cs)


static func _v3(a) -> Vector3:
	if a is Array and a.size() >= 3:
		return Vector3(float(a[0]), float(a[1]), float(a[2]))
	return Vector3.ZERO


func _material(s: Dictionary) -> Material:
	var key := String(s.get("m", "metal"))
	var base: Array = MATERIALS.get(key, MATERIALS.metal)
	var c := Color(String(s.get("c", base[0])))
	if key == "glass":
		c.a = 0.55
	return Models.mat(c, base[1], base[2])


func _shape_mesh(s: Dictionary) -> MeshInstance3D:
	var mat := _material(s)
	var pos := _v3(s.get("p", [0, 0, 0]))
	var rot := _v3(s.get("r", [0, 0, 0])) * (PI / 180.0)
	var mi: MeshInstance3D
	match String(s.get("t", "box")):
		"box":
			mi = Models.box(_v3(s.get("s", [0.1, 0.1, 0.1])), mat, pos, rot)
		"cyl":
			var r := float(s.get("rad", 0.01))
			mi = Models.cyl(float(s.get("rad2", r)), r, float(s.get("h", 0.1)), mat, pos, rot, int(s.get("seg", 14)))
		"cone":
			mi = Models.cyl(0.0, float(s.get("rad", 0.02)), float(s.get("h", 0.05)), mat, pos, rot, int(s.get("seg", 14)))
		"sphere":
			mi = Models.sphere(float(s.get("rad", 0.02)), mat, pos, _v3(s.get("s", [1, 1, 1])))
			mi.rotation = rot
		"torus":
			mi = Models.torus(float(s.get("rad", 0.02)), float(s.get("rad2", 0.03)), mat, pos, rot)
		"prism":
			mi = Models.prism(_v3(s.get("s", [0.1, 0.1, 0.1])), mat, pos, rot)
		_:
			mi = Models.box(Vector3.ONE * 0.05, mat, pos, rot)
	return mi


func _shape_collision(s: Dictionary) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	cs.position = _v3(s.get("p", [0, 0, 0]))
	cs.rotation = _v3(s.get("r", [0, 0, 0])) * (PI / 180.0)
	match String(s.get("t", "box")):
		"box", "prism":
			var b := BoxShape3D.new()
			var size := _v3(s.get("s", [0.1, 0.1, 0.1]))
			b.size = Vector3(max(size.x, 0.012), max(size.y, 0.012), max(size.z, 0.012))
			cs.shape = b
		"cyl", "cone":
			var c := CylinderShape3D.new()
			c.radius = max(float(s.get("rad", 0.01)), float(s.get("rad2", 0.0)), 0.008)
			c.height = float(s.get("h", 0.1))
			cs.shape = c
		"sphere":
			var sp := SphereShape3D.new()
			sp.radius = float(s.get("rad", 0.02)) * _v3(s.get("s", [1, 1, 1])).x
			cs.shape = sp
		"torus":
			var sp2 := SphereShape3D.new()
			sp2.radius = float(s.get("rad2", 0.03))
			cs.shape = sp2
		_:
			return null
	return cs


func exploded_transform(id: String) -> Transform3D:
	var t: Transform3D = home[id]
	var p: Dictionary = part_data[id]
	t.origin += _v3(p.get("explode", [0, 0, 0]))
	if p.has("explode_rot"):
		t.basis = Basis.from_euler(_v3(p.get("rot", [0, 0, 0])) * (PI / 180.0) + _v3(p.explode_rot) * (PI / 180.0))
	return t


## amount 0 = assemblé, 1 = vue éclatée.
func set_explode(amount: float) -> void:
	explode_amount = amount
	for id in parts:
		if removed.get(id, false):
			continue
		var a: Transform3D = home[id]
		var b := exploded_transform(id)
		parts[id].transform = a.interpolate_with(b, ease(amount, -2.0))


func tween_part(id: String, to_exploded: bool, duration := 0.6) -> void:
	var node: Node3D = parts[id]
	var target: Transform3D = exploded_transform(id) if to_exploded else home[id]
	var tw := create_tween()
	tw.tween_property(node, "transform", target, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


func reset_home() -> void:
	for id in parts:
		parts[id].transform = home[id]
		parts[id].scale = Vector3.ONE


func highlight(id: String) -> void:
	if id == _hovered:
		return
	if _hovered != "" and parts.has(_hovered):
		_set_overlay(parts[_hovered], null)
	_hovered = id
	if id != "" and parts.has(id):
		_set_overlay(parts[id], _hl_mat)


func _set_overlay(n: Node, m: Material) -> void:
	for c in n.get_children():
		if c is GeometryInstance3D:
			c.material_overlay = m


## Taille approximative de l'objet (pour cadrer la caméra).
func extent() -> float:
	return float(data.get("camera", {}).get("size", 1.0))
