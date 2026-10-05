class_name Ragdoll
extends RefCounted
## Transforme un soldat mort en poupée de chiffon physique (le côté « TABS »),
## et un véhicule détruit en épave (tourelle éjectée, flammes).

const MAX_BODIES := 700
const FREEZE_AFTER := 9.0

static var _bodies: Array = []
static var _phys_mat: PhysicsMaterial
static var _burnt: StandardMaterial3D


static func reset() -> void:
	_bodies.clear()


static func _mat() -> PhysicsMaterial:
	if _phys_mat == null:
		_phys_mat = PhysicsMaterial.new()
		_phys_mat.friction = 0.9
		_phys_mat.bounce = 0.15
	return _phys_mat


static func _body(parent: Node3D, xform: Transform3D, mass: float, shapes: Array) -> RigidBody3D:
	var rb := RigidBody3D.new()
	rb.mass = mass
	rb.collision_layer = 2
	rb.collision_mask = 1 | 2
	rb.physics_material_override = _mat()
	rb.angular_damp = 0.6
	rb.linear_damp = 0.05
	for s in shapes:
		var cs := CollisionShape3D.new()
		cs.shape = s[0]
		cs.position = s[1]
		if s.size() > 2:
			cs.rotation = s[2]
		rb.add_child(cs)
	parent.add_child(rb)
	rb.global_transform = xform.orthonormalized()
	_register(rb)
	return rb


static func _register(rb: RigidBody3D) -> void:
	_bodies.append(rb)
	while _bodies.size() > MAX_BODIES:
		var old = _bodies.pop_front()
		if is_instance_valid(old):
			old.freeze = true
	var tree := rb.get_tree()
	if tree:
		tree.create_timer(FREEZE_AFTER, false).timeout.connect(func():
			if is_instance_valid(rb) and rb.linear_velocity.length() < 1.0:
				rb.freeze = true)


static func _capsule(r: float, h: float) -> CapsuleShape3D:
	var c := CapsuleShape3D.new()
	c.radius = r
	c.height = max(h, r * 2.0)
	return c


static func _sphere(r: float) -> SphereShape3D:
	var s := SphereShape3D.new()
	s.radius = r
	return s


static func _boxs(size: Vector3) -> BoxShape3D:
	var b := BoxShape3D.new()
	b.size = size
	return b


static func _pin(parent: Node3D, at: Vector3, a: PhysicsBody3D, b: PhysicsBody3D) -> void:
	var j := PinJoint3D.new()
	parent.add_child(j)
	j.global_position = at
	j.node_a = j.get_path_to(a)
	j.node_b = j.get_path_to(b)


static func from_soldier(s: SoldierModel, parent: Node3D, impulse: Vector3) -> void:
	if not is_instance_valid(s) or not is_instance_valid(parent):
		return
	var sc := s.global_transform.basis.get_scale().x
	var t_body := s.body.global_transform
	var t_al := s.arm_l.global_transform
	var t_ar := s.arm_r.global_transform
	var t_ll := s.leg_l.global_transform
	var t_lr := s.leg_r.global_transform

	var torso := _body(parent, t_body, 3.0, [
		[_capsule(0.27 * sc, 0.86 * sc), Vector3(0, 0.4, 0) * sc],
		[_sphere(0.21 * sc), Vector3(0, 0.98, 0) * sc],
	])
	var arm_l := _body(parent, t_al, 0.7, [[_capsule(0.085 * sc, 0.6 * sc), Vector3(0, -0.27, 0) * sc]])
	var arm_r := _body(parent, t_ar, 0.7, [[_capsule(0.085 * sc, 0.6 * sc), Vector3(0, -0.27, 0) * sc]])
	var leg_l := _body(parent, t_ll, 0.9, [[_capsule(0.11 * sc, 0.62 * sc), Vector3(0, -0.3, 0) * sc]])
	var leg_r := _body(parent, t_lr, 0.9, [[_capsule(0.11 * sc, 0.62 * sc), Vector3(0, -0.3, 0) * sc]])

	s.arm_l.reparent(arm_l, true)
	s.arm_r.reparent(arm_r, true)
	s.leg_l.reparent(leg_l, true)
	s.leg_r.reparent(leg_r, true)
	s.body.reparent(torso, true)

	_pin(parent, t_al.origin, torso, arm_l)
	_pin(parent, t_ar.origin, torso, arm_r)
	_pin(parent, t_ll.origin, torso, leg_l)
	_pin(parent, t_lr.origin, torso, leg_r)

	var jitter := Vector3(randf_range(-1, 1), randf_range(0, 1), randf_range(-1, 1))
	torso.apply_central_impulse((impulse + jitter) * torso.mass)
	torso.angular_velocity = Vector3(randf_range(-6, 6), randf_range(-4, 4), randf_range(-6, 6))
	for limb in [arm_l, arm_r, leg_l, leg_r]:
		limb.apply_central_impulse((impulse * 0.8 + jitter * 2.0) * limb.mass)

	if s.mount:
		var h := s.mount
		var t_h := h.global_transform
		var horse := _body(parent, t_h, 6.0, [[_boxs(Vector3(0.62, 0.7, 1.8) * sc), Vector3(0, 1.08, 0) * sc]])
		h.reparent(horse, true)
		horse.apply_central_impulse((impulse * 0.5 + Vector3.UP) * horse.mass)
		horse.angular_velocity = Vector3(randf_range(-2, 2), 0, randf_range(-3, 3))


static func wreck_vehicle(v: VehicleModel, parent: Node3D, impulse: Vector3, battle: Node) -> void:
	if not is_instance_valid(v) or not is_instance_valid(parent):
		return
	if _burnt == null:
		_burnt = StandardMaterial3D.new()
		_burnt.albedo_color = Color("2a2724")
		_burnt.roughness = 1.0
	var pos := v.global_position
	# L'équipage est éjecté.
	for c in v.crew:
		if is_instance_valid(c):
			from_soldier(c, parent, impulse + Vector3(randf_range(-3, 3), 4, randf_range(-3, 3)))
	for h in v.horses:
		if is_instance_valid(h):
			var hb := _body(parent, h.global_transform, 5.0, [[_boxs(Vector3(0.6, 0.7, 1.7)), Vector3(0, 1.0, 0)]])
			h.reparent(hb, true)
			hb.apply_central_impulse((impulse * 0.5 + Vector3.UP * 2) * hb.mass)
	if v.hover_height > 0.0:
		# Les engins volants tombent en tournoyant puis explosent au sol.
		var size := 1.2 if v.kind == "drone" else 4.0
		var rb := _body(parent, v.global_transform, 4.0, [[_boxs(Vector3(size, size * 0.5, size * 1.5)), Vector3.ZERO]])
		v.reparent(rb, true)
		v.set_process(false)
		rb.apply_central_impulse((impulse + Vector3.UP * 2) * rb.mass)
		rb.angular_velocity = Vector3(randf_range(-3, 3), randf_range(-6, 6), randf_range(-3, 3))
		_burn(v)
		if v.kind != "drone":
			rb.get_tree().create_timer(1.4, false).timeout.connect(func():
				if is_instance_valid(rb) and is_instance_valid(battle):
					battle.fx.explosion(rb.global_position, 3.0)
					battle.fx.fire(rb.global_position, 20.0))
		return
	var turret_size := Vector3(1.2, 0.6, 1.4)
	if v.turret and v.kind in ["ft17", "medium_tank", "t55", "mbt"]:
		if v.kind == "ft17":
			turret_size = Vector3(0.9, 0.7, 0.9)
		elif v.kind == "mbt":
			turret_size = Vector3(2.4, 0.8, 3.0)
		var tr := _body(parent, v.turret.global_transform, 3.0, [[_boxs(turret_size), Vector3(0, turret_size.y / 2, 0)]])
		v.turret.reparent(tr, true)
		tr.apply_central_impulse((Vector3.UP * 9.0 + impulse * 0.4 + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))) * tr.mass)
		tr.angular_velocity = Vector3(randf_range(-4, 4), randf_range(-3, 3), randf_range(-4, 4))
		_burn(v.turret)
	# La carcasse reste sur place comme obstacle pour les corps.
	var hull := StaticBody3D.new()
	hull.collision_layer = 1
	var cs := CollisionShape3D.new()
	var half := 1.0
	match v.kind:
		"medium_tank": half = 2.0
		"t55": half = 2.3
		"mbt": half = 2.7
		"ft17": half = 1.3
	cs.shape = _boxs(Vector3(half * 1.1, 1.4, half * 2.2))
	cs.position = Vector3(0, 0.7, 0)
	hull.add_child(cs)
	parent.add_child(hull)
	hull.global_transform = v.global_transform.orthonormalized()
	v.reparent(hull, true)
	v.set_process(false)
	_burn(v)
	if is_instance_valid(battle):
		battle.fx.fire(pos + Vector3(0, 1.0, 0), 25.0)


static func _burn(n: Node) -> void:
	for c in n.get_children():
		if c is MeshInstance3D:
			c.material_override = _burnt
		_burn(c)
