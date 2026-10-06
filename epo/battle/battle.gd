extends Node3D
## Bataille 3D « façon TABS » : on place ses troupes avec un budget, puis la bataille se joue seule.
## Paramètres Nav : {"battle": id} | {"sandbox": true, "era": id} | {"challenge": code}

enum State { PLACEMENT, FIGHT, END }

const HALF_W := 46.0
const HALF_D := 44.0
const ZONE_NEAR := 4.0
const CELL := 4.0
const SPEEDS := [0.0, 0.25, 1.0, 2.0]
const TIME_LIMIT := 300.0
const HOLD_TIME := 100.0

var state := State.PLACEMENT
var scenario: Dictionary = {}
var sandbox := false
var is_challenge := false
var era_id := "e01"
var units: Array[BattleUnit] = []
var team_units: Array = [[], []]
var cam: RtsCamera
var fx: BattleFx
var corpses: Node3D
var projectiles: Node3D
var ground_mat: ShaderMaterial
var budget := 1500
var spent := [0, 0]
var place_team := 0
var selected_unit := ""
var allowed: Array = []
var era_filter := ""
var grid: Dictionary = {}
var fight_time := 0.0
var start_value := [0.0, 0.0]
var start_count := [0, 0]
var spotters := [0, 0]
var speed_idx := 2
var result_shown := false
var cover: Array = []
var mud := false
var stakes_z := INF

var ghost: Node3D
var _painting := false
var _last_paint := Vector3.INF
var _rpress := Vector2.ZERO
var _end_timer := -1.0

# Interface
var ui: Control
var place_panel: PanelContainer
var unit_list: VBoxContainer
var budget_label: Label
var budget_bar: ProgressBar
var team_buttons: Array = []
var fight_panel: Control
var count_label: Label
var time_label: Label
var speed_buttons: Array = []
var help_panel: PanelContainer
var follow_label: Label


func _ready() -> void:
	Ragdoll.reset()
	var p := Nav.params
	if p.has("challenge"):
		scenario = Challenge.decode(String(p.challenge))
		is_challenge = not scenario.is_empty()
	elif p.get("sandbox", false):
		sandbox = true
		var e := String(p.get("era", ""))
		scenario = {
			"id": "sandbox", "era": e if e != "" else "e08", "name": "Bac à sable",
			"player_side": "Bleus", "enemy_side": "Rouges", "budget": 0, "units": [],
			"intro": "Place librement les deux armées (bleue et rouge), mélange les époques, puis lance la bataille. Tu peux aussi créer un code de défi pour tes amis.",
		}
		era_filter = e
	else:
		scenario = Content.battle(String(p.get("battle", "")))
	if scenario.is_empty():
		scenario = Content.battles[0] if Content.battles.size() else {"id": "x", "era": "e01", "name": "Bataille", "enemy": []}
	era_id = String(scenario.get("era", "e01"))
	var era := Content.era(era_id)
	var terrain := String(scenario.get("terrain", era.get("terrain", "grass")))
	cover = scenario.get("cover", [])
	mud = bool(scenario.get("mud", false))
	stakes_z = float(scenario.get("stakes_z", INF))
	ground_mat = Battlefield.build(self, terrain, HALF_W, HALF_D, scenario.get("features", []), scenario)
	ground_mat.set_shader_parameter("zones", Vector4(ZONE_NEAR, HALF_D - 1.0, -HALF_D + 1.0, -ZONE_NEAR))
	ground_mat.set_shader_parameter("zone_alpha", 1.0)
	corpses = Node3D.new()
	corpses.name = "Corps"
	add_child(corpses)
	projectiles = Node3D.new()
	projectiles.name = "Projectiles"
	add_child(projectiles)
	fx = BattleFx.new()
	fx.battle = self
	add_child(fx)
	cam = RtsCamera.new()
	cam.target = Vector3(0, 0, 2)
	cam.dist = 50.0
	cam.pitch = -0.7
	add_child(cam)
	cam.snap()

	budget = int(scenario.get("budget", 1500))
	allowed = scenario.get("units", []).duplicate()
	if allowed.is_empty():
		if sandbox or is_challenge:
			allowed = Content.units.keys()
		else:
			allowed = Content.units_for_era(era_id).map(func(u): return u.id)
	for f in scenario.get("enemy", []):
		_spawn_formation(f, 1)
	for f in scenario.get("player_preset", []):
		_spawn_formation(f, 0)
	_build_ui()
	Sfx.music("march")
	if not sandbox and not Nav.params.get("nointro", false):
		_show_intro()
	set_physics_process(true)


# --- Création des unités -------------------------------------------------------

func _spawn_formation(f: Dictionary, team: int) -> void:
	var id := String(f.get("unit", ""))
	if not Content.units.has(id):
		return
	var rows := int(f.get("rows", 1))
	var cols := int(f.get("cols", 1))
	var sp := float(f.get("spacing", 1.6))
	var rsp := float(f.get("row_spacing", sp))
	var x0 := float(f.get("x", 0.0))
	var z0 := float(f.get("z", -15.0))
	for r in rows:
		for c in cols:
			var x := x0 + (c - (cols - 1) / 2.0) * sp
			var z := z0 + (r * rsp if team == 0 else -r * rsp)
			spawn_unit(id, team, Vector3(x, 0, z))


func spawn_unit(id: String, team: int, pos: Vector3) -> BattleUnit:
	var data: Dictionary = Content.units[id]
	var u := BattleUnit.new()
	u.name = "%s_%d" % [id, units.size()]
	add_child(u)
	u.setup(self, data, team, UI.BLUE_TEAM if team == 0 else UI.RED_TEAM)
	u.global_position = Vector3(pos.x, 0, pos.z)
	u.rotation.y = 0.0 if team == 0 else PI
	u.hold = (team == 0 and bool(scenario.get("defend", false))) or (team == 1 and bool(scenario.get("enemy_holds", false)))
	units.append(u)
	team_units[team].append(u)
	spent[team] += int(data.get("cost", 0))
	if bool(u.attack.get("spotter", false)):
		spotters[team] += 1
	return u


func remove_unit(u: BattleUnit) -> void:
	units.erase(u)
	team_units[u.team].erase(u)
	spent[u.team] -= int(u.data.get("cost", 0))
	if bool(u.attack.get("spotter", false)):
		spotters[u.team] -= 1
	u.queue_free()


func clamp_to_field(p: Vector3) -> Vector3:
	return Vector3(clamp(p.x, -HALF_W - 6, HALF_W + 6), p.y, clamp(p.z, -HALF_D - 6, HALF_D + 6))


# --- Boucle de combat -------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if state == State.PLACEMENT:
		for u in units:
			if u.soldier:
				u.soldier.animate(delta, 0.0, false)
			elif u.vehicle:
				u.vehicle.animate(delta, 0.0, false)
		return
	if state == State.END and _end_timer < 0.0:
		for u in units:
			u.tick(delta)
		return
	_rebuild_grid()
	_separate(delta)
	if stakes_z != INF:
		_check_stakes()
	for u in units.duplicate():
		if is_instance_valid(u) and u.alive:
			u.tick(delta)
	if state == State.FIGHT:
		fight_time += delta
		_update_hud()
		var a := _alive(0)
		var b := _alive(1)
		if (a == 0 or b == 0 or fight_time > TIME_LIMIT) and _end_timer < 0.0:
			_end_timer = 2.5
			Engine.time_scale = 0.35
	if _end_timer >= 0.0:
		_end_timer -= delta / max(Engine.time_scale, 0.01)
		if _end_timer < 0.0:
			Engine.time_scale = 1.0
			_finish()


## Facteur de dégâts reçus à distance selon les abris du scénario (1 = à découvert).
func cover_factor(u: BattleUnit) -> float:
	for c in cover:
		if int(c.get("team", 0)) == u.team and u.kind != "air":
			var z := u.global_position.z
			if z >= float(c.zmin) and z <= float(c.zmax):
				return float(c.get("factor", 0.5))
	return 1.0


## Pieux plantés devant les archers (Azincourt) : la cavalerie qui les franchit est blessée et stoppée.
func _check_stakes() -> void:
	for u in team_units[1]:
		if u.kind == "cavalry" and not u.stake_hit and abs(u.global_position.z - stakes_z) < 0.9 and abs(u.global_position.x) < HALF_W * 0.72:
			u.stake_hit = true
			u.velocity = Vector3.ZERO
			u.take_damage(70.0, Vector3(0, 0, -1), 4.0, null, true)


func _alive(team: int) -> int:
	return team_units[team].size()


func _rebuild_grid() -> void:
	grid.clear()
	for u in units:
		var c := Vector2i(floori(u.global_position.x / CELL), floori(u.global_position.z / CELL))
		u.cell = c
		if grid.has(c):
			grid[c].append(u)
		else:
			grid[c] = [u]


## Les corps ne se traversent pas : on écarte les unités qui se chevauchent.
func _separate(delta: float) -> void:
	for u in units:
		if u.is_air():
			continue
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				var list = grid.get(u.cell + Vector2i(dx, dz))
				if list == null:
					continue
				for o in list:
					if o == u or o.is_air() or o.get_instance_id() < u.get_instance_id():
						continue
					var d: Vector3 = o.global_position - u.global_position
					d.y = 0.0
					var min_d: float = u.radius + o.radius
					var l: float = d.length()
					if l < min_d and l > 0.0001:
						var push: Vector3 = d / l * (min_d - l)
						var mu := float(u.data.get("mass", 1.0))
						var mo := float(o.data.get("mass", 1.0))
						if u.speed <= 0.0:
							mu = 1000.0
						if o.speed <= 0.0:
							mo = 1000.0
						var tot := mu + mo
						u.global_position -= push * (mo / tot) * min(1.0, delta * 12.0)
						o.global_position += push * (mu / tot) * min(1.0, delta * 12.0)


func find_target(u: BattleUnit) -> BattleUnit:
	var best: BattleUnit = null
	var bd := INF
	var akind := String(u.attack.get("kind", "melee"))
	var proj := String(u.attack.get("projectile", ""))
	var no_air := akind == "melee" or proj in ["ball", "boulder", "shell", "stone"]
	var prefer_vehicle := String(u.attack.get("prefer", "")) == "vehicle"
	var min_r := float(u.attack.get("min_range", 0.0))
	for e in team_units[1 - u.team]:
		if not e.alive:
			continue
		if no_air and e.is_air():
			continue
		var d := u.global_position.distance_squared_to(e.global_position)
		if min_r > 0.0 and d < min_r * min_r:
			d += 1.0e6
		if prefer_vehicle and (e.kind == "vehicle" or e.kind == "air"):
			d *= 0.1
		if d < bd:
			bd = d
			best = e
	return best


## Teste si un segment (trajectoire d'un projectile) touche une unité ennemie.
func segment_hit(a: Vector3, b: Vector3, shooter_team: int, exclude: Dictionary) -> BattleUnit:
	var minx := floori((min(a.x, b.x) - 3.0) / CELL)
	var maxx := floori((max(a.x, b.x) + 3.0) / CELL)
	var minz := floori((min(a.z, b.z) - 3.0) / CELL)
	var maxz := floori((max(a.z, b.z) + 3.0) / CELL)
	var best: BattleUnit = null
	var best_t := INF
	var ab := b - a
	var len2 := ab.length_squared()
	if len2 < 0.000001:
		return null
	for cx in range(minx, maxx + 1):
		for cz in range(minz, maxz + 1):
			var list = grid.get(Vector2i(cx, cz))
			if list == null:
				continue
			for u in list:
				if u.team == shooter_team or not u.alive or exclude.has(u):
					continue
				var c: Vector3 = u.center()
				var r: float = u.radius + 0.3 if u.kind == "infantry" else u.radius * 0.9
				if u.kind == "infantry":
					r = 0.55
				elif u.kind == "cavalry":
					r = 0.95
				var t: float = clamp((c - a).dot(ab) / len2, 0.0, 1.0)
				var closest := a + ab * t
				var dist := closest.distance_to(c)
				var r_eff := r
				if u.kind == "infantry":
					# Corps vertical : on tolère plus de hauteur que de largeur.
					var dh := Vector2(closest.x - c.x, closest.z - c.z).length()
					dist = dh if abs(closest.y - c.y) < 0.85 else 999.0
				if dist < r_eff and t < best_t:
					best_t = t
					best = u
	return best


func fire(u: BattleUnit, target: BattleUnit) -> void:
	if not is_instance_valid(target):
		return
	var a := u.attack
	var proj := String(a.get("projectile", "bullet"))
	var from: Vector3
	if u.vehicle and u.vehicle.muzzle:
		from = u.vehicle.muzzle.global_position
	else:
		var h := 2.2 if u.soldier and u.soldier.mount else 1.45
		from = u.global_position + u.global_basis * Vector3(0.25, h, -0.8)
	var tpos := target.center()
	var spd := float(a.get("speed", 100.0))
	var g := 9.8
	if proj in ["bullet", "rocket"]:
		g = 0.0
	elif proj == "tank_shell":
		g = 1.5
	var hd := Vector2(tpos.x - from.x, tpos.z - from.z).length()
	var t_flight: float = hd / maxf(spd, 1.0)
	if proj in ["shell", "boulder"]:
		t_flight = maxf(t_flight, 1.4 + hd / 40.0)
	var spread := float(a.get("spread", 0.05))
	if spotters[u.team] > 0:
		spread *= 0.6
	if bool(a.get("guided", false)):
		spread = 0.0
	tpos += target.velocity * t_flight
	var dist := from.distance_to(tpos)
	# Dispersion : plus la cible est loin, plus le tir est imprécis.
	tpos += Vector3(randf_range(-1, 1), randf_range(-0.5, 0.5), randf_range(-1, 1)) * spread * dist
	var vel: Vector3
	if g == 0.0:
		vel = (tpos - from).normalized() * spd
	else:
		var hv := Vector3(tpos.x - from.x, 0, tpos.z - from.z)
		vel = hv / t_flight + Vector3.UP * ((tpos.y - from.y + 0.5 * g * t_flight * t_flight) / t_flight)
	var p := Projectile.new()
	p.setup(self, u.team, proj, from, vel, float(a.get("damage", 10)), float(a.get("splash", 0.0)), bool(a.get("anti_armor", false)))
	var big := proj in ["ball", "shell", "tank_shell", "boulder", "rocket"]
	if proj not in ["arrow", "bolt", "stone", "javelin", "boulder"]:
		fx.muzzle_flash(from, big)
	if bool(a.get("smoke", false)) or proj in ["ball", "shell", "tank_shell", "rocket"]:
		fx.smoke(from, 1.4 if big else 0.6, 3 if big else 2)
	Sfx.play_3d(String(a.get("sound", "rifle")), from, self, 2.0 if big else -6.0, 12 if not big else 6)


func explode(pos: Vector3, radius: float, damage: float, team: int, source: BattleUnit, anti_armor: bool) -> void:
	fx.explosion(pos, radius)
	var r2 := radius * 1.6
	for u in units.duplicate():
		if not is_instance_valid(u) or not u.alive or u.team == team or u == source:
			continue
		var c: Vector3 = u.center()
		var d: float = c.distance_to(pos)
		if d < r2:
			var k: float = clamp(1.0 - d / r2, 0.25, 1.0)
			var dir: Vector3 = (u.global_position - pos)
			dir.y = 0
			dir = dir.normalized() if dir.length() > 0.01 else Vector3.FORWARD
			u.take_damage(damage * k, dir, 9.0 * k, source, anti_armor)
	for c in corpses.get_children():
		if c is RigidBody3D and not c.freeze:
			var d: float = c.global_position.distance_to(pos)
			if d < r2 * 1.5:
				c.apply_central_impulse(((c.global_position - pos).normalized() + Vector3.UP) * 6.0 * c.mass * (1.0 - d / (r2 * 1.5)))


func on_unit_died(u: BattleUnit) -> void:
	units.erase(u)
	team_units[u.team].erase(u)
	if bool(u.attack.get("spotter", false)):
		spotters[u.team] -= 1
	if cam.follow == u:
		cam.follow = null
		if follow_label:
			follow_label.visible = false
	if u.team == 1 and Game.has_profile():
		Game.current.stats.enemies = int(Game.current.stats.get("enemies", 0)) + 1


# --- Placement (souris) ---------------------------------------------------------

func _zone_ok(p: Vector3, team: int) -> bool:
	if p == Vector3.INF or abs(p.x) > HALF_W - 0.5:
		return false
	if team == 0:
		return p.z > ZONE_NEAR and p.z < HALF_D - 1.0
	return p.z < -ZONE_NEAR and p.z > -HALF_D + 1.0


func _can_afford(id: String, team: int) -> bool:
	if sandbox:
		return true
	if team == 1:
		return false
	return spent[0] + int(Content.units[id].get("cost", 0)) <= budget


func _free_spot(p: Vector3, radius: float) -> bool:
	for u in units:
		if Vector2(u.global_position.x - p.x, u.global_position.z - p.z).length() < (u.radius + radius) * 0.92:
			return false
	return true


func _try_place(p: Vector3) -> bool:
	if selected_unit == "" or not _zone_ok(p, place_team):
		return false
	var data: Dictionary = Content.units[selected_unit]
	var r := float(data.get("radius", 0.45))
	if not _free_spot(p, r):
		return false
	if not _can_afford(selected_unit, place_team):
		Sfx.play("error")
		UI.toast("Budget insuffisant !", UI.RED, 1.2)
		_painting = false
		return false
	spawn_unit(selected_unit, place_team, p)
	Sfx.play("part", -6.0, randf_range(0.9, 1.2))
	_refresh_budget()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				if cam.follow:
					cam.follow = null
					follow_label.visible = false
			KEY_P, KEY_PAUSE:
				if state == State.FIGHT:
					_set_speed(0 if speed_idx != 0 else 2)
	if state == State.FIGHT and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p := cam.mouse_ground(event.position)
		var best: BattleUnit = null
		var bd := 3.0
		for u in units:
			var d := Vector2(u.global_position.x - p.x, u.global_position.z - p.z).length()
			if d < bd:
				bd = d
				best = u
		if best:
			cam.follow = best
			cam.dist = 14.0
			follow_label.text = "Caméra : %s  (Échap pour libérer)" % best.data.get("name", "")
			follow_label.visible = true
	if state != State.PLACEMENT:
		return
	if event is InputEventMouseMotion:
		var p := cam.mouse_ground(event.position)
		_update_ghost(p)
		if _painting and p != Vector3.INF:
			var spacing := float(Content.units.get(selected_unit, {}).get("radius", 0.45)) * 2.0 + 0.35
			if _last_paint == Vector3.INF or p.distance_to(_last_paint) >= spacing:
				if _try_place(p):
					_last_paint = p
	elif event is InputEventMouseButton:
		var p := cam.mouse_ground(event.position)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_painting = true
				_last_paint = p if _try_place(p) else Vector3.INF
			else:
				_painting = false
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_rpress = event.position
			elif event.position.distance_to(_rpress) < 6.0:
				_remove_near(p)


func _remove_near(p: Vector3) -> void:
	if p == Vector3.INF:
		return
	var best: BattleUnit = null
	var bd := 2.0
	for u in units:
		if not sandbox and u.team != 0:
			continue
		var d := Vector2(u.global_position.x - p.x, u.global_position.z - p.z).length()
		if d < bd:
			bd = d
			best = u
	if best:
		remove_unit(best)
		Sfx.play("click")
		_refresh_budget()


func _update_ghost(p: Vector3) -> void:
	if ghost == null:
		return
	var ok := _zone_ok(p, place_team) and selected_unit != ""
	ghost.visible = p != Vector3.INF and selected_unit != ""
	if ghost.visible:
		ghost.global_position = p
		ghost.rotation.y = 0.0 if place_team == 0 else PI
		_set_transparency(ghost, 0.45 if ok else 0.8)


func _set_transparency(n: Node, t: float) -> void:
	for c in n.get_children():
		if c is GeometryInstance3D:
			c.transparency = t
			c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_set_transparency(c, t)


func _select_unit(id: String) -> void:
	selected_unit = id
	if ghost:
		ghost.queue_free()
		ghost = null
	if id != "":
		ghost = UnitFactory.build_model(Content.units[id], UI.BLUE_TEAM if place_team == 0 else UI.RED_TEAM)
		add_child(ghost)
		ghost.visible = false
		_set_transparency(ghost, 0.45)
	_refresh_unit_list()


# --- Placement automatique ----------------------------------------------------------

func auto_place(team := 0) -> void:
	var pool: Array = []
	for id in allowed:
		if Content.units.has(id):
			pool.append(Content.units[id])
	if era_filter != "" and sandbox:
		pool = pool.filter(func(u): return u.era == era_filter)
	if pool.is_empty():
		return
	var melee := pool.filter(func(u): return u.type == "infantry" and u.attack.kind == "melee")
	var ranged := pool.filter(func(u): return u.type == "infantry" and u.attack.kind == "ranged")
	var cav := pool.filter(func(u): return u.type == "cavalry")
	var heavy := pool.filter(func(u): return u.type in ["artillery", "vehicle", "air"])
	var cap := budget if not sandbox else 2000
	var sgn := 1.0 if team == 0 else -1.0
	var money: int = cap - (int(spent[team]) if not sandbox else 0)
	var plan := []
	if not melee.is_empty():
		plan.append([melee, 0.4, 7.0, 1.7])
	if not ranged.is_empty():
		plan.append([ranged, 0.35 if not melee.is_empty() else 0.65, 11.0 if not melee.is_empty() else 7.0, 1.6])
	if not cav.is_empty():
		plan.append([cav, 0.15, 9.0, 2.2])
	if not heavy.is_empty():
		plan.append([heavy, 0.25, 18.0, 5.0])
	# En défense, les tireurs se placent dans la zone abritée.
	for c in cover:
		if int(c.get("team", 0)) == team and team == 0:
			for step in plan:
				if step[0] == ranged:
					step[2] = float(c.zmin) + 1.0
				elif step[0] == melee:
					step[2] = float(c.zmin) + 4.0
	var total_share := 0.0
	for step in plan:
		total_share += step[1]
	for step in plan:
		var group: Array = step[0]
		var share := int(money * step[1] / total_share)
		var row_z: float = step[2]
		var sp: float = step[3]
		var placed := 0
		var guard := 0
		while share > 0 and guard < 200:
			guard += 1
			var choice: Dictionary = group[randi() % group.size()]
			var cost := int(choice.get("cost", 100))
			if cost > share:
				var cheaper := group.filter(func(u): return int(u.cost) <= share)
				if cheaper.is_empty():
					break
				choice = cheaper[randi() % cheaper.size()]
				cost = int(choice.cost)
			var per_row := 14 if sp < 3.0 else 5
			var col := placed % per_row
			var row := placed / per_row
			var x := (col - (per_row - 1) / 2.0) * sp
			if choice.type == "cavalry":
				x = (-1 if placed % 2 == 0 else 1) * (HALF_W * 0.6 + (placed / 2) % 3 * 2.4)
			var p := Vector3(x, 0, sgn * (row_z + row * sp))
			if _zone_ok(p, team) and _free_spot(p, float(choice.get("radius", 0.45))):
				spawn_unit(choice.id, team, p)
				share -= cost
			placed += 1
	_refresh_budget()


# --- Lancement et fin -------------------------------------------------------------

func start_battle() -> void:
	if _alive(0) == 0:
		UI.toast("Place au moins une unité !", UI.RED)
		Sfx.play("error")
		return
	if _alive(1) == 0:
		UI.toast("Il n'y a aucun ennemi à combattre.", UI.RED)
		Sfx.play("error")
		return
	state = State.FIGHT
	if ghost:
		ghost.queue_free()
		ghost = null
	ground_mat.set_shader_parameter("zone_alpha", 0.0)
	for t in 2:
		start_count[t] = _alive(t)
		start_value[t] = 0.0
		for u in team_units[t]:
			start_value[t] += float(u.data.get("cost", 0))
	place_panel.visible = false
	fight_panel.visible = true
	Sfx.play("whistle")
	Sfx.music("battle")
	_set_speed(2)


func _team_value(t: int) -> float:
	var v := 0.0
	for u in team_units[t]:
		v += float(u.data.get("cost", 0)) * u.hp / u.max_hp
	return v


func _finish() -> void:
	if result_shown:
		return
	result_shown = true
	state = State.END
	var a := _alive(0)
	var b := _alive(1)
	var win := b == 0 and a > 0
	if fight_time > TIME_LIMIT and a > 0 and b > 0:
		win = _team_value(0) / max(1.0, start_value[0]) > _team_value(1) / max(1.0, start_value[1])
	var stars := 0
	var survive_ratio: float = _team_value(0) / maxf(1.0, start_value[0])
	if win:
		stars = 1
		if survive_ratio >= 0.35:
			stars += 1
		if sandbox or spent[0] <= budget * 0.8:
			stars += 1
	Sfx.music("")
	Sfx.play("victory" if win else "defeat")
	if Game.has_profile() and not sandbox:
		if win:
			Game.stat_add("battles_won")
		else:
			Game.stat_add("battles_lost")
	var reward_text := ""
	if win and not sandbox and Game.has_profile():
		var key := "battle_" + String(scenario.get("id", ""))
		var prev := int(Game.best(key, 0))
		var xp := 30
		if stars > prev:
			xp = 60 + 40 * stars
			Game.set_best(key, stars)
		Game.reward(xp, 30 + 20 * stars, "Bataille gagnée")
		Game.set_step(era_id, "battle", stars)
		reward_text = "\n[color=#d4ac2b]+%d XP · +%d de solde[/color]" % [xp, 30 + 20 * stars]
	_show_result(win, stars, reward_text)


func _show_result(win: bool, stars: int, reward_text: String) -> void:
	fight_panel.visible = false
	var v := UI.vbox(12)
	var t := UI.title("VICTOIRE !" if win else "DÉFAITE…", 54, UI.GOLD if win else UI.RED)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	if win and not sandbox:
		var s := UI.label(UI.stars(stars), 48, UI.GOLD)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(s)
	var lost: int = start_count[0] - _alive(0)
	var killed: int = start_count[1] - _alive(1)
	var stats := "Unités perdues : [b]%d / %d[/b]   ·   Ennemis vaincus : [b]%d / %d[/b]   ·   Durée : [b]%d s[/b]" % [lost, start_count[0], killed, start_count[1], int(fight_time)]
	if not sandbox:
		stats += "\nArmée engagée : [b]%d / %d[/b]" % [spent[0], budget]
	v.add_child(UI.rich(stats + reward_text, false, 19))
	var deb := String(scenario.get("debrief", ""))
	var tip := String(scenario.get("tip", ""))
	if deb != "":
		var hp := UI.paper_panel(18)
		var col := UI.vbox(6)
		hp.add_child(col)
		col.add_child(UI.label("CE QUI S'EST VRAIMENT PASSÉ", 18, UI.INK, UI.font_ui_bold))
		col.add_child(UI.rich(deb, true, 18, UI.INK))
		v.add_child(hp)
	if not win and tip != "":
		v.add_child(UI.rich("[color=#d4ac2b]Conseil :[/color] " + tip, true, 18))
	if win and not sandbox and stars < 3:
		v.add_child(UI.rich("[color=#a8a48c]3 étoiles : gagne en gardant au moins 35 % de ton armée et en dépensant 80 % du budget au maximum.[/color]", false, 16))
	var row := UI.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	row.add_child(UI.primary_button("↻  Rejouer", func(): Nav.goto("battle", Nav.params), 22))
	row.add_child(UI.button("Voir le champ de bataille", func():
		get_tree().call_group("battle_modal", "queue_free"), 20))
	row.add_child(UI.button("Quitter", _back, 20))
	var m := UI.modal(ui, v, 760)
	m.add_to_group("battle_modal")


func _back() -> void:
	Engine.time_scale = 1.0
	if sandbox or is_challenge:
		Nav.goto("battle_menu", {"sandbox": true})
	else:
		Nav.goto("battle_menu", {"era": era_id})


# --- Interface ----------------------------------------------------------------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = UI.root_control()
	layer.add_child(ui)
	ui.add_child(UI.top_bar(String(scenario.get("name", "Bataille")), _back))

	# Panneau de placement
	place_panel = UI.panel(14, Color(UI.PANEL, 0.93))
	place_panel.anchor_top = 0.0
	place_panel.anchor_bottom = 1.0
	place_panel.offset_top = 74
	place_panel.offset_bottom = -12
	place_panel.offset_left = 12
	place_panel.offset_right = 372
	ui.add_child(place_panel)
	var col := UI.vbox(8)
	place_panel.add_child(col)
	if sandbox:
		col.add_child(UI.label("BAC À SABLE", 22, UI.GOLD, UI.font_ui_bold))
		var trow := UI.hbox(6)
		for t in 2:
			var b := UI.button("Placer les %s" % ["Bleus", "Rouges"][t], func(): _set_place_team(t), 17)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.toggle_mode = true
			b.button_pressed = t == 0
			team_buttons.append(b)
			trow.add_child(b)
		col.add_child(trow)
		var ob := OptionButton.new()
		ob.add_item("Toutes les époques")
		for e in Content.eras:
			ob.add_item("%d. %s" % [e.num, e.name])
		ob.selected = 0 if era_filter == "" else Content.era_index(era_filter) + 1
		ob.item_selected.connect(func(i):
			era_filter = "" if i == 0 else Content.eras[i - 1].id
			_refresh_unit_list())
		col.add_child(ob)
	else:
		col.add_child(UI.label("TU COMMANDES : %s" % String(scenario.get("player_side", "")).to_upper(), 18, UI.BLUE_TEAM.lightened(0.3), UI.font_ui_bold))
		col.add_child(UI.label("FACE À : %s" % String(scenario.get("enemy_side", "")).to_upper(), 16, UI.RED_TEAM.lightened(0.3), UI.font_ui_bold))
	unit_list = UI.vbox(6)
	col.add_child(UI.scroll(unit_list))
	budget_label = UI.label("", 19, UI.TEXT, UI.font_ui_bold)
	col.add_child(budget_label)
	budget_bar = UI.progress_bar(0, max(1, budget), false, 12)
	if not sandbox:
		col.add_child(budget_bar)
	var r1 := UI.hbox(6)
	var b_auto := UI.button("Placement auto", func():
		auto_place(place_team), 17)
	b_auto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_auto.tooltip_text = "L'ordinateur dépense ton budget à ta place (infanterie devant, tireurs derrière, artillerie au fond)."
	r1.add_child(b_auto)
	var b_clear := UI.button("Tout effacer", func():
		for u in units.duplicate():
			if sandbox and u.team != place_team:
				continue
			if not sandbox and u.team != 0:
				continue
			remove_unit(u)
		_refresh_budget(), 17)
	b_clear.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r1.add_child(b_clear)
	col.add_child(r1)
	var r2 := UI.hbox(6)
	var b_info := UI.button("Contexte historique", _show_intro, 17)
	b_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r2.add_child(b_info)
	if sandbox:
		var b_code := UI.button("Code de défi", _challenge_dialog, 17)
		b_code.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r2.add_child(b_code)
	col.add_child(r2)
	col.add_child(UI.primary_button("⚔  LANCER LA BATAILLE", start_battle, 24))

	help_panel = UI.panel(10, Color("0f120b", 0.8))
	UI.pin(help_panel, 1.0, 1.0, -12, -12)
	help_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var help := UI.label("Clic gauche : placer (maintenir pour peindre une ligne)\nClic droit : retirer · Clic droit glissé : tourner la vue\nMolette : zoom · ZQSD / flèches : déplacer · Maj : rapide\nAttaque de flanc +25 %, dans le dos +50 % !", 15, UI.MUTED)
	help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	help_panel.add_child(help)
	ui.add_child(help_panel)

	# Interface de combat
	fight_panel = Control.new()
	fight_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fight_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fight_panel.visible = false
	ui.add_child(fight_panel)
	var top := UI.panel(10, Color("0f120b", 0.85), UI.BORDER)
	UI.pin(top, 0.5, 0.0, 0, 76)
	fight_panel.add_child(top)
	var trow2 := UI.hbox(20)
	top.add_child(trow2)
	count_label = UI.label("", 26, UI.TEXT, UI.font_ui_bold)
	trow2.add_child(count_label)
	time_label = UI.label("", 20, UI.MUTED)
	trow2.add_child(time_label)
	var bottom := UI.panel(8, Color("0f120b", 0.85), UI.BORDER)
	UI.pin(bottom, 0.5, 1.0, 0, -14)
	fight_panel.add_child(bottom)
	var brow := UI.hbox(8)
	bottom.add_child(brow)
	var names := ["❚❚ Pause", "Ralenti ×0,25", "Normal ×1", "Rapide ×2"]
	for i in 4:
		var b := UI.button(names[i], func(): _set_speed(i), 18)
		b.toggle_mode = true
		speed_buttons.append(b)
		brow.add_child(b)
	brow.add_child(UI.spacer(0, 16))
	brow.add_child(UI.button("↻ Recommencer", func(): Nav.goto("battle", Nav.params), 18))
	follow_label = UI.label("", 18, UI.GOLD, UI.font_ui_bold)
	UI.pin(follow_label, 0.5, 1.0, 0, -84)
	follow_label.visible = false
	fight_panel.add_child(follow_label)
	var hint := UI.label("Astuce : clique sur un soldat pour le suivre avec la caméra.", 15, UI.MUTED)
	UI.pin(hint, 0.0, 1.0, 16, -16)
	fight_panel.add_child(hint)
	_refresh_unit_list()
	_refresh_budget()


func _set_place_team(t: int) -> void:
	place_team = t
	for i in team_buttons.size():
		team_buttons[i].button_pressed = i == t
	_select_unit(selected_unit)


func _set_speed(i: int) -> void:
	speed_idx = i
	Engine.time_scale = SPEEDS[i]
	for k in speed_buttons.size():
		speed_buttons[k].button_pressed = k == i


func _refresh_unit_list() -> void:
	if unit_list == null:
		return
	for c in unit_list.get_children():
		c.queue_free()
	var ids: Array = allowed.duplicate()
	if sandbox and era_filter != "":
		ids = ids.filter(func(id): return Content.units[id].era == era_filter)
	ids.sort_custom(func(a, b):
		var ea := Content.era_index(Content.units[a].era)
		var eb := Content.era_index(Content.units[b].era)
		if ea != eb:
			return ea < eb
		return int(Content.units[a].cost) < int(Content.units[b].cost))
	for id in ids:
		if not Content.units.has(id):
			continue
		unit_list.add_child(_unit_card(Content.units[id]))


func _unit_card(u: Dictionary) -> Control:
	var b := Button.new()
	b.toggle_mode = true
	b.button_pressed = selected_unit == u.id
	b.custom_minimum_size = Vector2(0, 58)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var types := {"infantry": "Infanterie", "cavalry": "Cavalerie", "artillery": "Artillerie", "vehicle": "Véhicule", "air": "Aérien"}
	var a: Dictionary = u.attack
	var role := "corps à corps" if a.kind == "melee" else ("kamikaze" if a.kind == "kamikaze" else "portée %d m" % int(a.get("range", 0)))
	b.tooltip_text = "%s\n%s · PV %d · vitesse %s m/s · %s\n\n%s" % [u.name, types.get(u.type, ""), int(u.hp), UI.dec(float(u.speed)), role, u.get("desc", "")]
	var row := UI.hbox(8)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 10
	row.offset_right = -10
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)
	var v := UI.vbox(0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var n := UI.label(u.name, 18, UI.TEXT, UI.font_ui_bold)
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(n)
	var sub := "%s · %s" % [types.get(u.type, ""), role]
	if sandbox:
		sub = "%s · %s" % [Content.era(u.era).get("name", ""), types.get(u.type, "")]
	var s := UI.label(sub, 14, UI.MUTED)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(s)
	row.add_child(v)
	var c := UI.label("◉ %d" % int(u.cost), 18, UI.GOLD, UI.font_ui_bold)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(c)
	b.pressed.connect(func():
		Sfx.play("click")
		_select_unit(u.id if selected_unit != u.id else ""))
	return b


func _refresh_budget() -> void:
	if budget_label == null:
		return
	if sandbox:
		budget_label.text = "Bleus : %d unités (◉ %d)   Rouges : %d unités (◉ %d)" % [_alive(0), spent[0], _alive(1), spent[1]]
		budget_label.add_theme_font_size_override("font_size", 15)
	else:
		budget_label.text = "Budget : ◉ %d / %d   (%d unités)" % [spent[0], budget, _alive(0)]
		budget_bar.max_value = max(1, budget)
		budget_bar.value = spent[0]


func _update_hud() -> void:
	count_label.text = "BLEUS  %d   ⚔   %d  ROUGES" % [_alive(0), _alive(1)]
	var left := TIME_LIMIT - fight_time
	time_label.text = "%d:%02d" % [int(left) / 60, int(left) % 60]


func _show_intro() -> void:
	var body := String(scenario.get("intro", ""))
	if scenario.has("date"):
		body = "[b]%s[/b]\n\n%s" % [scenario.date, body]
	if scenario.has("tip") and not sandbox:
		body += "\n\n[color=#8a6f17][b]Conseil tactique :[/b][/color] " + String(scenario.tip)
	if not sandbox:
		body += "\n\n[i]Budget : ◉ %d. Place tes troupes dans la zone bleue, puis lance la bataille.[/i]" % budget
	UI.message(ui, String(scenario.get("name", "")), body, "À vos ordres !")


func _challenge_dialog() -> void:
	var v := UI.vbox(12)
	v.add_child(UI.title("Codes de défi", 30))
	v.add_child(UI.rich("Place une armée [color=#cf3d3a]rouge[/color], puis génère un code : ton ami devra la battre avec le même budget que toi (le coût de l'armée rouge).", false, 18))
	var out := LineEdit.new()
	out.placeholder_text = "Le code apparaîtra ici"
	out.editable = false
	v.add_child(out)
	var shade: Control
	var gen := UI.primary_button("Générer et copier le code", func():
		if _alive(1) == 0:
			UI.toast("Place d'abord des unités rouges.", UI.RED)
			return
		var allowed_ids := []
		if era_filter != "":
			allowed_ids = Content.units_for_era(era_filter).map(func(u): return u.id)
		var code := Challenge.encode("Défi de " + String(Game.current.get("name", "?")), era_filter if era_filter != "" else era_id, spent[1], team_units[1], allowed_ids)
		out.text = code
		DisplayServer.clipboard_set(code)
		UI.toast("Code copié dans le presse-papiers !", UI.GREEN), 19)
	v.add_child(gen)
	v.add_child(HSeparator.new())
	v.add_child(UI.label("Relever un défi reçu :", 19, UI.TEXT, UI.font_ui_bold))
	var inp := LineEdit.new()
	inp.placeholder_text = "Colle ici le code EPO1-…"
	v.add_child(inp)
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(row)
	row.add_child(UI.button("Fermer", func(): shade.queue_free(), 18))
	row.add_child(UI.primary_button("Relever le défi", func():
		var sc := Challenge.decode(inp.text)
		if sc.is_empty():
			UI.toast("Code invalide.", UI.RED)
			Sfx.play("error")
			return
		Nav.goto("battle", {"challenge": inp.text.strip_edges()}), 18))
	shade = UI.modal(ui, v, 700)


## Utilisé par les tests automatiques (captures d'écran).
func test_action(a: String) -> void:
	match a:
		"auto":
			auto_place(0)
		"fight", "end":
			auto_place(0)
			start_battle()
			var limit := 8.0 if a == "fight" else 200.0
			var t := 0.0
			Engine.time_scale = 2.0 if a == "end" else 1.0
			while t < limit and state == State.FIGHT:
				await get_tree().physics_frame
				t += get_physics_process_delta_time() * Engine.time_scale
			if a == "end":
				while not result_shown:
					await get_tree().process_frame
			print("TEST battle state=", state, " alive=", _alive(0), "/", _alive(1), " t=", fight_time)
