class_name Projectile
extends Node3D
## Projectile balistique : balle, flèche, carreau, pierre, boulet, obus, roquette.
## Les boulets ricochent sur le sol (comme les vrais boulets pleins, qui traversaient plusieurs rangs).

var battle: Node
var team := 0
var kind := "bullet"
var vel := Vector3.ZERO
var damage := 10.0
var splash := 0.0
var anti_armor := false
var gravity := 9.8
var life := 6.0
var bounces := 0
var shooter_name := ""
var _hit: Dictionary = {}
var _stuck := false
var _trail_timer := 0.0

static var _meshes: Dictionary = {}


static func make_mesh(k: String) -> Node3D:
	var n := Node3D.new()
	match k:
		"bullet":
			var t := Models.box(Vector3(0.035, 0.035, 1.1), Models.mat(Color(1.0, 0.85, 0.4), 0.5, 0.0, 3.0))
			t.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			n.add_child(t)
		"arrow", "bolt", "javelin":
			var length: float = {"arrow": 0.8, "bolt": 0.5, "javelin": 1.5}[k]
			n.add_child(Models.cyl(0.012, 0.012, length, Models.mat(Color("8a6a3a")), Vector3.ZERO, Vector3(PI / 2, 0, 0), 5))
			n.add_child(Models.cyl(0.0, 0.025, 0.08, Models.metal_mat(Color("8a8f94")), Vector3(0, 0, -length / 2), Vector3(-PI / 2, 0, 0), 5))
			if k == "arrow":
				n.add_child(Models.box(Vector3(0.06, 0.002, 0.12), Models.mat(Color("e8e0c8")), Vector3(0, 0, length / 2 - 0.06)))
		"stone":
			n.add_child(Models.sphere(0.06, Models.mat(Color("8a8579"))))
		"ball":
			n.add_child(Models.sphere(0.13, Models.metal_mat(Color("2a2a2a"))))
		"boulder":
			n.add_child(Models.sphere(0.32, Models.mat(Color("8a8579"))))
		"shell", "tank_shell":
			n.add_child(Models.cyl(0.06, 0.07, 0.35, Models.metal_mat(Color("6b6b4a")), Vector3.ZERO, Vector3(PI / 2, 0, 0), 8))
		"rocket":
			n.add_child(Models.cyl(0.05, 0.05, 0.6, Models.mat(Color("4b5a32")), Vector3.ZERO, Vector3(PI / 2, 0, 0), 8))
			n.add_child(Models.sphere(0.08, Models.mat(Color(1.0, 0.6, 0.2), 0.5, 0.0, 4.0), Vector3(0, 0, 0.35)))
	return n


func setup(b: Node, t: int, k: String, from: Vector3, velocity: Vector3, dmg: float, spl: float, ap: bool) -> void:
	battle = b
	team = t
	kind = k
	vel = velocity
	damage = dmg
	splash = spl
	anti_armor = ap
	gravity = 0.0 if k in ["bullet", "rocket", "tank_shell"] else 9.8
	if k == "tank_shell":
		gravity = 1.5
	life = 2.0 if k == "bullet" else 8.0
	add_child(make_mesh(k))
	b.projectiles.add_child(self)
	global_position = from
	_orient()


func _orient() -> void:
	if vel.length() > 0.1:
		var fwd := vel.normalized()
		var up := Vector3.UP if abs(fwd.y) < 0.98 else Vector3.RIGHT
		global_basis = Basis.looking_at(fwd, up)


func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	if _stuck:
		return
	var prev := global_position
	vel.y -= gravity * delta
	var next := prev + vel * delta
	if kind == "rocket" or kind == "shell":
		_trail_timer -= delta
		if _trail_timer <= 0.0:
			_trail_timer = 0.05
			battle.fx.smoke(prev, 0.25, 1, kind == "shell")
	var hit: BattleUnit = battle.segment_hit(prev, next, team, _hit)
	if hit:
		_on_unit(hit, next)
		return
	if next.y <= 0.02:
		_on_ground(Vector3(next.x, 0.0, next.z))
		return
	global_position = next
	_orient()


func _on_unit(u: BattleUnit, at: Vector3) -> void:
	var dir := vel.normalized()
	if splash > 0.0 and kind != "ball":
		battle.explode(at, splash, damage, team, null, anti_armor)
		queue_free()
		return
	var kb := 2.0
	match kind:
		"ball", "boulder":
			kb = 10.0
		"javelin", "bolt":
			kb = 3.0
		"bullet":
			kb = 1.5
	u.take_damage(damage, Vector3(dir.x, 0, dir.z).normalized(), kb, null, anti_armor)
	Sfx.play_3d("hit", at, battle, -12.0, 10)
	if kind == "ball":
		# Le boulet continue sa course en perdant de l'énergie.
		_hit[u] = true
		damage *= 0.75
		vel *= 0.8
		if vel.length() < 8.0:
			queue_free()
		return
	queue_free()


func _on_ground(at: Vector3) -> void:
	match kind:
		"ball":
			if bounces < 2 and vel.length() > 10.0:
				bounces += 1
				battle.fx.dust(at, 0.5)
				vel.y = abs(vel.y) * 0.35
				vel.x *= 0.7
				vel.z *= 0.7
				global_position = at + Vector3(0, 0.05, 0)
				return
			_stick(at)
		"boulder", "shell", "rocket", "tank_shell":
			if splash > 0.0:
				battle.explode(at, splash, damage, team, null, anti_armor)
			else:
				battle.fx.dust(at, 0.6)
			queue_free()
		"arrow", "bolt", "javelin":
			_stick(at)
		_:
			if randf() < 0.3:
				battle.fx.dust(at, 0.2)
			queue_free()


func _stick(at: Vector3) -> void:
	_stuck = true
	global_position = at + vel.normalized() * 0.15
	life = 6.0
