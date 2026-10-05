class_name SoldierModel
extends Node3D
## Soldat « façon TABS » : corps rond, petites jambes, gros yeux, animations procédurales.
## L'avant du soldat est -Z.

const HIP := 0.62
const GUNS := ["arquebus", "musket", "musket_bayonet", "flintlock", "rifle", "rifle_bayonet", "garand", "ak", "m16", "famas", "smg", "mg", "fal", "bazooka", "rpg", "sniper"]
const POLES := ["spear", "pilum", "lance", "pike", "halberd"]
const MELEE := ["gladius", "sword", "sabre", "axe", "mace", "torch"]
const BOWS := ["bow", "longbow"]

var cfg: Dictionary = {}
var rig: Node3D
var body: Node3D
var head: Node3D
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var weapon: Node3D
var shield_node: Node3D
var mount: HorseModel
var hold := "none"
var weapon_kind := ""
var phase := randf() * TAU
var attack_t := -1.0
var attack_len := 0.35
var aim := 0.0
var _t := randf() * 10.0
var _wobble := Vector2.ZERO
var _wobble_v := Vector2.ZERO


func build(c: Dictionary) -> void:
	cfg = c
	var uni := Models.col(c.get("uniform"), Color("6b6b4f"))
	var pants := Models.col(c.get("pants"), uni.darkened(0.15))
	var trim := Models.col(c.get("trim"), Color("3b2f20"))
	var boots := Models.col(c.get("boots"), Color("2a221a"))
	var skin := Color(Models.SKINS[int(c.get("skin", 1)) % Models.SKINS.size()])
	var helmet := Models.col(c.get("helmet"), uni.darkened(0.1))
	var accent := Models.col(c.get("accent"), Color("c23a3a"))
	var team = c.get("team", null)

	var m_uni := Models.mat(uni)
	var m_pants := Models.mat(pants)
	var m_trim := Models.mat(trim)
	var m_boots := Models.mat(boots, 0.6)
	var m_skin := Models.mat(skin, 0.75)

	rig = Node3D.new()
	add_child(rig)

	# Jambes
	leg_l = _leg(Vector3(-0.13, HIP, 0), m_pants, m_boots)
	leg_r = _leg(Vector3(0.13, HIP, 0), m_pants, m_boots)
	rig.add_child(leg_l)
	rig.add_child(leg_r)

	# Corps
	body = Node3D.new()
	body.position = Vector3(0, HIP, 0)
	rig.add_child(body)
	body.add_child(Models.capsule(0.27, 0.86, m_uni, Vector3(0, 0.4, 0), Vector3.ZERO, Vector3(1.05, 1, 0.86)))
	body.add_child(Models.cyl(0.29, 0.29, 0.08, m_trim, Vector3(0, 0.12, 0), Vector3.ZERO, 14))
	if c.get("pack", false):
		body.add_child(Models.box(Vector3(0.38, 0.4, 0.18), Models.mat(uni.darkened(0.3)), Vector3(0, 0.48, 0.28)))
	if c.get("armor", false):
		body.add_child(Models.capsule(0.285, 0.6, Models.metal_mat(Color("9aa0a6")), Vector3(0, 0.5, 0), Vector3.ZERO, Vector3(1.05, 1, 0.88)))
	if c.get("vest", "") != "":
		body.add_child(Models.capsule(0.285, 0.55, Models.mat(Color(c.vest), 0.8), Vector3(0, 0.5, 0), Vector3.ZERO, Vector3(1.06, 1, 0.9)))
	if c.get("cape", "") != "":
		body.add_child(Models.box(Vector3(0.5, 0.75, 0.04), Models.mat(Color(c.cape)), Vector3(0, 0.38, 0.26), Vector3(0.12, 0, 0)))

	# Tête
	head = Node3D.new()
	head.position = Vector3(0, 0.98, 0)
	body.add_child(head)
	head.add_child(Models.sphere(0.21, m_skin))
	var white := Models.mat(Color.WHITE, 0.4)
	var black := Models.mat(Color("111111"), 0.3)
	for sx in [-1.0, 1.0]:
		head.add_child(Models.sphere(0.055, white, Vector3(0.075 * sx, 0.035, -0.172), Vector3(1, 1.15, 0.6)))
		head.add_child(Models.sphere(0.03, black, Vector3(0.075 * sx, 0.03, -0.205), Vector3(1, 1.1, 0.5)))
	if c.get("beard", false):
		head.add_child(Models.sphere(0.13, Models.mat(Color("4a3220")), Vector3(0, -0.12, -0.1), Vector3(1.1, 0.8, 0.8)))
	if c.get("mustache", false):
		head.add_child(Models.box(Vector3(0.16, 0.035, 0.04), Models.mat(Color("3a2818")), Vector3(0, -0.04, -0.2)))
	var hg := String(c.get("headgear", "hair"))
	if hg == "":
		hg = "hair"
	var hair_col := helmet if hg != "hair" else Color(["3a2818", "1c1612", "6b4a2a", "b08a4a", "222222"][int(c.get("skin", 1)) % 5])
	head.add_child(Models.headgear(hg, hair_col, accent))

	# Bras
	arm_l = _arm(Vector3(-0.35, 0.68, 0), m_uni, m_skin, m_trim)
	arm_r = _arm(Vector3(0.35, 0.68, 0), m_uni, m_skin, m_trim)
	body.add_child(arm_l)
	body.add_child(arm_r)
	if team is Color:
		var band := Models.cyl(0.095, 0.095, 0.09, Models.mat(team, 0.6, 0.0, 0.25), Vector3(0, -0.14, 0), Vector3.ZERO, 10)
		arm_l.add_child(band)
		var band2 := Models.cyl(0.095, 0.095, 0.09, Models.mat(team, 0.6, 0.0, 0.25), Vector3(0, -0.14, 0), Vector3.ZERO, 10)
		arm_r.add_child(band2)

	# Arme
	weapon_kind = String(c.get("weapon", ""))
	if weapon_kind != "":
		weapon = Models.hand_weapon(weapon_kind)
		if weapon_kind in GUNS:
			hold = "gun"
		elif weapon_kind in POLES:
			hold = "pole"
		elif weapon_kind in BOWS:
			hold = "bow"
		elif weapon_kind in MELEE:
			hold = "melee"
		elif weapon_kind == "flag":
			hold = "flag"
		else:
			hold = "item"
		var hand: Node3D = (arm_l if hold == "bow" else arm_r).get_node("Hand")
		hand.add_child(weapon)

	var sk := String(c.get("shield", ""))
	if sk != "":
		shield_node = Models.shield(sk, Models.col(c.get("shield_color"), accent), Models.col(c.get("shield_accent"), Color("d6b13f")))
		shield_node.position = Vector3(-0.05, 0.05, -0.1)
		arm_l.get_node("Hand").add_child(shield_node)

	# Monture
	if String(c.get("mount", "")) == "horse":
		mount = Models.horse(Models.col(c.get("horse_color"), Color("5a3b22")))
		add_child(mount)
		rig.position = Vector3(0, 0.78, 0.05)
		leg_l.rotation = Vector3(1.2, 0, -0.45)
		leg_r.rotation = Vector3(1.2, 0, 0.45)

	scale = Vector3.ONE * float(c.get("scale", 1.0))
	_pose(0.0)


func _leg(pos: Vector3, m_pants: Material, m_boots: Material) -> Node3D:
	var p := Node3D.new()
	p.position = pos
	p.add_child(Models.capsule(0.11, 0.6, m_pants, Vector3(0, -0.29, 0)))
	p.add_child(Models.box(Vector3(0.19, 0.12, 0.28), m_boots, Vector3(0, -0.56, -0.04)))
	return p


func _arm(pos: Vector3, m_uni: Material, m_skin: Material, m_trim: Material) -> Node3D:
	var p := Node3D.new()
	p.position = pos
	p.add_child(Models.capsule(0.085, 0.56, m_uni, Vector3(0, -0.25, 0)))
	p.add_child(Models.cyl(0.09, 0.09, 0.05, m_trim, Vector3(0, -0.47, 0), Vector3.ZERO, 10))
	var hand := Node3D.new()
	hand.name = "Hand"
	hand.position = Vector3(0, -0.55, 0)
	p.add_child(hand)
	hand.add_child(Models.sphere(0.075, m_skin))
	return p


## Lance l'animation d'attaque (coup, tir, tir à l'arc…).
func play_attack(duration := 0.35) -> void:
	attack_t = 0.0
	attack_len = max(0.1, duration)


## speed : vitesse de déplacement (m/s). aiming : l'unité vise / combat.
func animate(delta: float, speed: float, aiming: bool) -> void:
	_t += delta
	var walk: float = clamp(speed / 2.5, 0.0, 1.0)
	phase += delta * (2.0 + speed * 3.2)
	aim = move_toward(aim, 1.0 if aiming else 0.0, delta * 4.0)
	if attack_t >= 0.0:
		attack_t += delta / attack_len
		if attack_t >= 1.0:
			attack_t = -1.0
	# Petit ressort pour l'effet « bancal » des corps.
	var target := Vector2(sin(phase * 0.5) * 0.07 * walk, -0.05 * walk)
	_wobble_v += (target - _wobble) * 60.0 * delta
	_wobble_v *= 0.86
	_wobble += _wobble_v * delta
	if mount:
		mount.animate(delta, speed)
		rig.position.y = 0.78 + mount.bob
	else:
		leg_l.rotation.x = sin(phase) * 0.75 * walk
		leg_r.rotation.x = -sin(phase) * 0.75 * walk
		body.position.y = HIP + abs(sin(phase)) * 0.06 * walk + sin(_t * 2.0) * 0.006
	body.rotation.z = _wobble.x
	body.rotation.x = _wobble.y
	_pose(walk)


func _pose(walk: float) -> void:
	var swing := sin(phase) * 0.55 * walk
	var a := attack_t if attack_t >= 0.0 else -1.0
	match hold:
		"gun":
			var up := lerpf(0.9, 1.5, aim)
			var recoil := 0.0
			if a >= 0.0:
				recoil = sin(a * PI) * 0.35
			arm_r.rotation = Vector3(up + recoil * 0.5, -0.12, 0.0)
			arm_r.position.z = recoil * 0.12
			arm_l.rotation = Vector3(up + 0.05, -0.62, 0.0)
			body.rotation.x += -recoil * 0.15
		"melee":
			if a >= 0.0:
				var k := a
				arm_r.rotation = Vector3(lerpf(2.8, 0.2, ease(k, 0.4)), 0, lerpf(0.2, -0.3, k))
				body.rotation.y = lerpf(-0.3, 0.35, k)
			else:
				arm_r.rotation = Vector3(lerpf(0.4 - swing, 1.9, aim), 0, 0.1)
				body.rotation.y = lerpf(body.rotation.y, 0.0, 0.2)
			arm_l.rotation = Vector3(lerpf(swing, 1.1, aim) if shield_node else swing, 0.0, -0.1)
		"pole":
			var thrust := sin(a * PI) * 0.35 if a >= 0.0 else 0.0
			arm_r.rotation = Vector3(lerpf(0.5 + swing * 0.3, 1.35, aim), 0.0, 0.0)
			arm_r.position.z = -thrust
			if weapon:
				weapon.rotation.x = lerpf(0.0, -PI / 2, aim)
			arm_l.rotation = Vector3(lerpf(swing, 1.1, aim) if shield_node else lerpf(swing, 1.3, aim), -0.3 * aim, 0.0)
		"bow":
			var draw := 0.0
			if a >= 0.0:
				draw = 1.0 - a
			arm_l.rotation = Vector3(lerpf(0.4, 1.55, aim), 0.15, 0.0)
			arm_r.rotation = Vector3(lerpf(swing, 1.5, aim), -0.4 * aim, 0.0)
			arm_r.position.z = 0.25 * aim * (0.4 + draw * 0.6)
		"flag":
			arm_r.rotation = Vector3(0.35, 0, 0.0)
			arm_l.rotation = Vector3(-swing, 0, 0)
		_:
			var item_up := 0.0
			if a >= 0.0:
				item_up = sin(a * PI) * 1.5
			arm_r.rotation = Vector3(-swing + item_up + aim * 0.6, 0, 0.05)
			arm_l.rotation = Vector3(swing if not shield_node else 1.1, 0, -0.05)
	if shield_node:
		shield_node.rotation.x = -arm_l.rotation.x
		shield_node.rotation.y = -arm_l.rotation.y
