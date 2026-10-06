class_name HorseModel
extends Node3D
## Cheval low-poly avec galop procédural. L'avant est -Z.

var legs: Array[Node3D] = []
var neck: Node3D
var torso: Node3D
var phase := randf() * TAU
var bob := 0.0


func build(c: Color) -> void:
	var m := Models.mat(c, 0.8)
	var dark := Models.mat(c.darkened(0.55), 0.8)
	var hoof := Models.mat(Color("1d1a14"))
	torso = Node3D.new()
	torso.position = Vector3(0, 1.08, 0)
	add_child(torso)
	torso.add_child(Models.capsule(0.34, 1.6, m, Vector3.ZERO, Vector3(PI / 2, 0, 0), Vector3(0.9, 1, 1)))
	torso.add_child(Models.box(Vector3(0.62, 0.08, 0.6), Models.mat(Color("6b2f24")), Vector3(0, 0.31, 0.05)))
	neck = Node3D.new()
	neck.position = Vector3(0, 0.15, -0.6)
	neck.rotation.x = -0.75
	torso.add_child(neck)
	neck.add_child(Models.capsule(0.15, 0.8, m, Vector3(0, 0.32, 0)))
	neck.add_child(Models.box(Vector3(0.06, 0.62, 0.12), dark, Vector3(0, 0.34, 0.12)))
	var head := Node3D.new()
	head.position = Vector3(0, 0.7, 0)
	head.rotation.x = 1.25
	neck.add_child(head)
	head.add_child(Models.box(Vector3(0.2, 0.22, 0.5), m, Vector3(0, 0.0, -0.2)))
	head.add_child(Models.box(Vector3(0.05, 0.12, 0.05), m, Vector3(0.07, 0.14, 0.0)))
	head.add_child(Models.box(Vector3(0.05, 0.12, 0.05), m, Vector3(-0.07, 0.14, 0.0)))
	for sx in [-1.0, 1.0]:
		head.add_child(Models.sphere(0.03, Models.mat(Color("111111"), 0.3), Vector3(0.1 * sx, 0.04, -0.1)))
	torso.add_child(Models.capsule(0.06, 0.6, dark, Vector3(0, 0.05, 0.85), Vector3(-0.6, 0, 0)))
	for pos in [Vector3(-0.2, 1.0, -0.55), Vector3(0.2, 1.0, -0.55), Vector3(-0.2, 1.0, 0.55), Vector3(0.2, 1.0, 0.55)]:
		var leg := Node3D.new()
		leg.position = pos
		leg.add_child(Models.capsule(0.075, 1.0, m, Vector3(0, -0.48, 0)))
		leg.add_child(Models.cyl(0.08, 0.09, 0.1, hoof, Vector3(0, -0.95, 0)))
		add_child(leg)
		legs.append(leg)


func animate(delta: float, speed: float) -> void:
	var gallop: float = clamp(speed / 5.0, 0.0, 1.0)
	phase += delta * (1.5 + speed * 1.8)
	var s := sin(phase)
	legs[0].rotation.x = s * 0.8 * gallop
	legs[1].rotation.x = sin(phase + 0.5) * 0.8 * gallop
	legs[2].rotation.x = -s * 0.7 * gallop
	legs[3].rotation.x = -sin(phase + 0.5) * 0.7 * gallop
	bob = abs(s) * 0.12 * gallop
	torso.position.y = 1.08 + bob
	torso.rotation.x = s * 0.06 * gallop
	neck.rotation.x = -0.75 + cos(phase) * 0.12 * gallop
