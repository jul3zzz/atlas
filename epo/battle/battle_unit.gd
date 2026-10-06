class_name BattleUnit
extends Node3D
## Une unité sur le champ de bataille : déplacement, choix de cible, attaque, mort.

var battle: Node  # battle.gd
var data: Dictionary
var id := ""
var team := 0
var hp := 100.0
var max_hp := 100.0
var speed := 2.5
var radius := 0.5
var kind := "infantry"
var armor := 0.0
var attack: Dictionary
var model: Node3D
var soldier: SoldierModel
var vehicle: VehicleModel
var ring: MeshInstance3D
var target: BattleUnit
var alive := true
var velocity := Vector3.ZERO
var knock := Vector3.ZERO
var cooldown := 0.0
var retarget_timer := 0.0
var burst_left := 0
var cell := Vector2i.ZERO
var kills := 0
var hold := false
var stake_hit := false
var _hit_flash := 0.0
var _engine_sound_timer := 0.0


func setup(b: Node, unit_data: Dictionary, team_id: int, team_color: Color) -> void:
	battle = b
	data = unit_data
	id = String(unit_data.get("id", ""))
	team = team_id
	max_hp = float(unit_data.get("hp", 100))
	hp = max_hp
	speed = float(unit_data.get("speed", 2.5))
	if battle.mud:
		# Boue (Azincourt, Verdun) : les troupes en armure et les chevaux s'enlisent.
		if float(unit_data.get("armor", 0.0)) >= 0.3 or String(unit_data.get("type", "")) == "cavalry":
			speed *= 0.55
		else:
			speed *= 0.85
	radius = float(unit_data.get("radius", 0.45))
	kind = String(unit_data.get("type", "infantry"))
	armor = float(unit_data.get("armor", 0.0))
	attack = unit_data.get("attack", {})
	model = UnitFactory.build_model(unit_data, team_color)
	add_child(model)
	if model is SoldierModel:
		soldier = model
	elif model is VehicleModel:
		vehicle = model
	ring = Models.cyl(radius + 0.12, radius + 0.12, 0.02, Models.mat(Color(team_color, 0.55), 0.9, 0.0, 0.4), Vector3(0, 0.03, 0), Vector3.ZERO, 20)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	cooldown = randf_range(0.0, float(attack.get("cooldown", 1.0)))
	retarget_timer = randf() * 0.3


func is_air() -> bool:
	return kind == "air"


func center() -> Vector3:
	var h := 1.0
	if vehicle:
		h = 1.2 + vehicle.hover_height
	elif soldier and soldier.mount:
		h = 1.8
	return global_position + Vector3(0, h, 0)


func tick(delta: float) -> void:
	if not alive:
		return
	cooldown -= delta
	retarget_timer -= delta
	if _hit_flash > 0.0:
		_hit_flash -= delta
	if retarget_timer <= 0.0 or not _valid(target):
		target = battle.find_target(self)
		retarget_timer = randf_range(0.4, 0.8)

	var desired := Vector3.ZERO
	var aiming := false
	var rng := float(attack.get("range", 1.5))
	if _valid(target):
		var to := target.global_position - global_position
		to.y = 0.0
		var dist := to.length() - radius - target.radius
		var dir := to.normalized() if to.length() > 0.01 else -global_basis.z
		var min_rng := float(attack.get("min_range", 0.0))
		var holding: bool = hold and battle.fight_time < battle.HOLD_TIME
		if holding and String(attack.get("kind", "melee")) == "melee" and dist < 9.0:
			holding = false
		if dist > rng * 0.92 and not holding:
			desired = dir * speed
		elif dist < min_rng and speed > 0.0:
			desired = -dir * speed * 0.6
		aiming = dist <= rng * 1.3
		_face(dir, delta)
		if dist <= rng and cooldown <= 0.0:
			_do_attack(dist)
	# Inertie : les cavaliers et les véhicules accélèrent progressivement.
	var accel := 6.0 if kind == "infantry" else 2.5
	velocity = velocity.lerp(desired, clamp(accel * delta, 0.0, 1.0))
	var step := (velocity + knock) * delta
	knock = knock.lerp(Vector3.ZERO, clamp(5.0 * delta, 0.0, 1.0))
	global_position += step
	global_position = battle.clamp_to_field(global_position)
	var spd := velocity.length()
	if soldier:
		soldier.animate(delta, spd, aiming)
	elif vehicle:
		vehicle.animate(delta, spd, aiming)
		if vehicle.turret and _valid(target):
			var local: Vector3 = (vehicle.turret.get_parent() as Node3D).to_local(target.global_position)
			var want := atan2(-local.x, -local.z)
			vehicle.turret.rotation.y = lerp_angle(vehicle.turret.rotation.y, want, clamp(3.0 * delta, 0.0, 1.0))
		if kind == "vehicle" and spd > 0.3:
			_engine_sound_timer -= delta
			if _engine_sound_timer <= 0.0:
				_engine_sound_timer = 2.0
				Sfx.play_3d("engine", global_position, battle, -10.0, 4)
	if _hit_flash > 0.0 and model:
		model.scale = Vector3.ONE * (1.0 + _hit_flash * 0.25) * float(data.get("model", {}).get("scale", 1.0))
	elif model and soldier:
		model.scale = Vector3.ONE * float(data.get("model", {}).get("scale", 1.0))


func _valid(u) -> bool:
	return u != null and is_instance_valid(u) and u.alive


func _face(dir: Vector3, delta: float) -> void:
	if dir.length() < 0.01:
		return
	var want := atan2(-dir.x, -dir.z)
	var turn := 8.0 if kind == "infantry" else 2.5
	rotation.y = lerp_angle(rotation.y, want, clamp(turn * delta, 0.0, 1.0))


func _do_attack(dist: float) -> void:
	var cd := float(attack.get("cooldown", 1.0))
	var burst := int(attack.get("burst", 0))
	if burst > 0:
		if burst_left <= 0:
			burst_left = burst
		burst_left -= 1
		cooldown = cd if burst_left > 0 else float(attack.get("burst_pause", 1.0)) + randf() * 0.3
	else:
		cooldown = cd * randf_range(0.9, 1.15)
	var akind := String(attack.get("kind", "melee"))
	if soldier:
		soldier.play_attack(0.3 if akind == "melee" else min(0.3, cd * 0.8))
	if vehicle:
		vehicle.fire_anim()
	match akind:
		"melee":
			_melee_hit()
		"ranged":
			battle.fire(self, target)
		"kamikaze":
			battle.explode(global_position + Vector3(0, 0.5, 0), float(attack.get("splash", 2.0)), float(attack.get("damage", 200)), team, self, true)
			die(Vector3.UP * 4.0)


func _melee_hit() -> void:
	if not _valid(target):
		return
	var dmg := float(attack.get("damage", 20))
	var charge := float(attack.get("charge", 1.0))
	var moving_fast := velocity.length() > speed * 0.6
	if charge > 1.0 and moving_fast:
		dmg *= charge
	var anti_cav := float(attack.get("anti_cavalry", 1.0))
	if target.kind == "cavalry":
		dmg *= anti_cav
	var dir := (target.global_position - global_position)
	dir.y = 0
	dir = dir.normalized()
	var kb := float(attack.get("knockback", 2.0)) * (1.6 if moving_fast and charge > 1.0 else 1.0)
	Sfx.play_3d(String(attack.get("sound", "sword")), global_position, battle, -4.0)
	target.take_damage(dmg, dir, kb, self)
	# Un piquier frappé par une charge renvoie une partie du choc au cavalier.
	if kind == "cavalry" and _valid(target) and float(target.attack.get("anti_cavalry", 1.0)) > 1.0:
		take_damage(float(target.attack.get("damage", 20)) * 0.6, -dir, 3.0, target)


func take_damage(amount: float, dir: Vector3, knockback: float, attacker: BattleUnit = null, anti_armor := false) -> void:
	if not alive:
		return
	var eff := amount
	# Bonus de flanc et de dos : c'est tout l'intérêt de l'encerclement (Cannes !).
	if attacker and is_instance_valid(attacker) and kind != "vehicle":
		var to_att := attacker.global_position - global_position
		to_att.y = 0.0
		if to_att.length() > 0.01:
			var facing := -global_basis.z
			var d := facing.dot(to_att.normalized())
			if d < -0.4:
				eff *= 1.5
			elif d < 0.3:
				eff *= 1.25
	# À couvert (tranchée, muret, bunker), on encaisse beaucoup moins les tirs.
	if attacker == null:
		eff *= battle.cover_factor(self)
	if anti_armor:
		eff *= 1.0 - armor * 0.15
	else:
		eff *= 1.0 - armor
		if kind == "vehicle" or (kind == "air" and armor >= 0.3):
			eff *= 0.15
	hp -= eff
	_hit_flash = 0.15
	var mass := float(data.get("mass", 1.0))
	if kind == "infantry" or kind == "cavalry":
		knock += dir * knockback / mass
	if hp <= 0.0:
		if attacker and is_instance_valid(attacker):
			attacker.kills += 1
		die(dir * (2.0 + knockback * 1.5) + Vector3.UP * (1.5 + knockback * 0.6))


func die(impulse: Vector3) -> void:
	if not alive:
		return
	alive = false
	battle.on_unit_died(self)
	if soldier:
		Ragdoll.from_soldier(soldier, battle.corpses, impulse)
	elif vehicle:
		Ragdoll.wreck_vehicle(vehicle, battle.corpses, impulse, battle)
	queue_free()
