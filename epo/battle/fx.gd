class_name BattleFx
extends Node3D
## Effets visuels de la bataille : éclairs de bouche, fumée de poudre, explosions, incendies.

var battle: Node
var _smoke_mat: StandardMaterial3D
var _flash_mat: StandardMaterial3D
var _fire_mat: StandardMaterial3D
var _dirt_mat: StandardMaterial3D
var _dark_smoke: StandardMaterial3D
var _sphere: SphereMesh
var _box: BoxMesh
var active := 0
const MAX_ACTIVE := 260


func _ready() -> void:
	_smoke_mat = StandardMaterial3D.new()
	_smoke_mat.albedo_color = Color(0.86, 0.85, 0.82, 0.55)
	_smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	_smoke_mat.roughness = 1.0
	_dark_smoke = _smoke_mat.duplicate()
	_dark_smoke.albedo_color = Color(0.18, 0.17, 0.16, 0.6)
	_flash_mat = StandardMaterial3D.new()
	_flash_mat.albedo_color = Color(1.0, 0.85, 0.4)
	_flash_mat.emission_enabled = true
	_flash_mat.emission = Color(1.0, 0.7, 0.25)
	_flash_mat.emission_energy_multiplier = 4.0
	_flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fire_mat = _flash_mat.duplicate()
	_fire_mat.albedo_color = Color(1.0, 0.45, 0.1)
	_fire_mat.emission = Color(1.0, 0.35, 0.05)
	_dirt_mat = StandardMaterial3D.new()
	_dirt_mat.albedo_color = Color(0.3, 0.24, 0.17)
	_sphere = SphereMesh.new()
	_sphere.radius = 0.5
	_sphere.height = 1.0
	_sphere.radial_segments = 10
	_sphere.rings = 5
	_box = BoxMesh.new()
	_box.size = Vector3(0.18, 0.18, 0.18)


func _spawn(mesh: Mesh, mat: Material, pos: Vector3, scl: float) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	m.global_position = pos
	m.scale = Vector3.ONE * scl
	active += 1
	m.tree_exited.connect(func(): active -= 1)
	return m


func muzzle_flash(pos: Vector3, big := false) -> void:
	if active > MAX_ACTIVE:
		return
	var f := _spawn(_sphere, _flash_mat, pos, 0.5 if big else 0.22)
	var tw := f.create_tween()
	tw.tween_property(f, "scale", Vector3.ONE * (1.2 if big else 0.4), 0.06)
	tw.tween_callback(f.queue_free)


func smoke(pos: Vector3, size := 1.0, count := 3, dark := false) -> void:
	for i in count:
		if active > MAX_ACTIVE:
			return
		var p := pos + Vector3(randf_range(-0.3, 0.3), randf_range(0, 0.3), randf_range(-0.3, 0.3)) * size
		var s := _spawn(_sphere, _dark_smoke if dark else _smoke_mat, p, size * randf_range(0.5, 0.8))
		var life := randf_range(1.6, 3.0) * size
		var tw := s.create_tween().set_parallel()
		tw.tween_property(s, "scale", Vector3.ONE * size * randf_range(1.8, 2.8), life).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "position", s.position + Vector3(randf_range(-0.6, 0.6), randf_range(0.8, 1.8), randf_range(-0.6, 0.6)) * size, life)
		tw.tween_property(s, "transparency", 1.0, life)
		tw.chain().tween_callback(s.queue_free)


func dust(pos: Vector3, size := 0.6) -> void:
	if active > MAX_ACTIVE:
		return
	var s := _spawn(_sphere, _dark_smoke, pos, size)
	s.transparency = 0.5
	var tw := s.create_tween().set_parallel()
	tw.tween_property(s, "scale", Vector3.ONE * size * 2.0, 0.6)
	tw.tween_property(s, "transparency", 1.0, 0.6)
	tw.chain().tween_callback(s.queue_free)


func explosion(pos: Vector3, size := 2.0) -> void:
	Sfx.play_3d("explosion" if size >= 2.0 else "cannon", pos, battle, 2.0 if size >= 2.0 else -2.0, 6)
	if battle and battle.cam:
		battle.cam.shake(0.25 * size, pos)
	var ball := _spawn(_sphere, _fire_mat, pos + Vector3(0, 0.3, 0), 0.4)
	var tw := ball.create_tween()
	tw.tween_property(ball, "scale", Vector3.ONE * size * 2.0, 0.18).set_ease(Tween.EASE_OUT)
	tw.tween_property(ball, "transparency", 1.0, 0.15)
	tw.tween_callback(ball.queue_free)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.25)
	light.light_energy = 6.0
	light.omni_range = size * 6.0
	add_child(light)
	light.global_position = pos + Vector3(0, 1.0, 0)
	var lt := light.create_tween()
	lt.tween_property(light, "light_energy", 0.0, 0.35)
	lt.tween_callback(light.queue_free)
	smoke(pos + Vector3(0, 0.5, 0), size * 0.9, 4, true)
	for i in int(6 + size * 3):
		if active > MAX_ACTIVE:
			break
		var d := _spawn(_box, _dirt_mat, pos + Vector3(0, 0.2, 0), randf_range(0.6, 1.4))
		var v := Vector3(randf_range(-1, 1), randf_range(1.5, 3.0), randf_range(-1, 1)) * size * 2.2
		var t := randf_range(0.7, 1.2)
		var dt := d.create_tween().set_parallel()
		dt.tween_method(func(k: float):
			if is_instance_valid(d):
				d.global_position = pos + Vector3(v.x * k * t, max(0.05, v.y * k * t - 4.9 * pow(k * t, 2) * 1.6), v.z * k * t), 0.0, 1.0, t)
		dt.tween_property(d, "rotation", Vector3(randf() * 8, randf() * 8, randf() * 8), t)
		dt.chain().tween_interval(2.0)
		dt.chain().tween_callback(d.queue_free)
	# Cratère
	var crater := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = size * 0.8
	cm.bottom_radius = size * 0.8
	cm.height = 0.02
	crater.mesh = cm
	crater.material_override = Models.mat(Color(0.12, 0.1, 0.08, 0.75), 1.0)
	crater.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(crater)
	crater.global_position = Vector3(pos.x, 0.025, pos.z)


func fire(pos: Vector3, duration := 20.0) -> void:
	var root := Node3D.new()
	add_child(root)
	root.global_position = pos
	var flames: Array = []
	for i in 3:
		var f := MeshInstance3D.new()
		f.mesh = _sphere
		f.material_override = _fire_mat
		f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		f.position = Vector3(randf_range(-0.5, 0.5), 0.3 + i * 0.2, randf_range(-0.5, 0.5))
		root.add_child(f)
		flames.append(f)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.5, 0.2)
	light.light_energy = 2.0
	light.omni_range = 8.0
	light.position = Vector3(0, 1.0, 0)
	root.add_child(light)
	var timer := Timer.new()
	timer.wait_time = 0.12
	timer.autostart = true
	root.add_child(timer)
	var elapsed := [0.0]
	timer.timeout.connect(func():
		elapsed[0] += timer.wait_time
		for f in flames:
			f.scale = Vector3.ONE * randf_range(0.5, 1.1)
		light.light_energy = randf_range(1.2, 2.4)
		if randi() % 3 == 0:
			smoke(pos + Vector3(0, 1.2, 0), 0.8, 1, true)
		if elapsed[0] > duration:
			root.queue_free())
