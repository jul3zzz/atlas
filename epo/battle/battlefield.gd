class_name Battlefield
extends RefCounted
## Construit le décor d'une bataille selon le terrain de l'époque.

const TERRAINS := {
	"grass": {"ground": "5f7a3a", "ground2": "6f8a45", "sky_top": "4a78b0", "sky_horizon": "b8cde0", "fog": "b8c8d0", "trees": "leafy", "tree_col": "3f6a2a"},
	"dry": {"ground": "a08a52", "ground2": "8a7a48", "sky_top": "5a8ac0", "sky_horizon": "e0d6b8", "fog": "e0d6c0", "trees": "olive", "tree_col": "6b7a42"},
	"mud": {"ground": "5a4a36", "ground2": "4a3e2e", "sky_top": "6a7078", "sky_horizon": "a8a8a0", "fog": "9a9a92", "trees": "dead", "tree_col": "3a3028"},
	"snow": {"ground": "dfe4e8", "ground2": "c8d0d8", "sky_top": "7890a8", "sky_horizon": "d8e0e8", "fog": "d0d8e0", "trees": "pine", "tree_col": "2f4a32"},
	"jungle": {"ground": "3f5a2a", "ground2": "4a6a30", "sky_top": "5a8aa0", "sky_horizon": "c8d8c0", "fog": "a8c0a0", "trees": "palm", "tree_col": "2f6a2a"},
	"desert": {"ground": "c8a870", "ground2": "b89860", "sky_top": "5a90c8", "sky_horizon": "f0e0c0", "fog": "e8d8b8", "trees": "rock", "tree_col": "8a7a5a"},
}

const GROUND_SHADER := """
shader_type spatial;
uniform vec4 c1 : source_color;
uniform vec4 c2 : source_color;
uniform vec4 zone_blue : source_color = vec4(0.24, 0.5, 0.82, 0.0);
uniform vec4 zone_red : source_color = vec4(0.82, 0.24, 0.23, 0.0);
uniform float zone_alpha = 0.0;
uniform vec4 zones = vec4(3.0, 30.0, -30.0, -3.0);
uniform float half_width = 40.0;
varying vec3 wpos;
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float n = noise(wpos.xz * 0.08) * 0.6 + noise(wpos.xz * 0.6) * 0.3 + noise(wpos.xz * 3.0) * 0.1;
	vec3 col = mix(c1.rgb, c2.rgb, n);
	bool in_x = abs(wpos.x) < half_width;
	if (zone_alpha > 0.0 && in_x) {
		if (wpos.z > zones.x && wpos.z < zones.y) {
			float edge = step(wpos.z, zones.x + 0.25) + step(zones.y - 0.25, wpos.z) + step(half_width - 0.25, abs(wpos.x));
			col = mix(col, zone_blue.rgb, zone_alpha * (0.14 + 0.7 * min(edge, 1.0)));
		} else if (wpos.z > zones.z && wpos.z < zones.w) {
			float edge2 = step(wpos.z, zones.z + 0.25) + step(zones.w - 0.25, wpos.z) + step(half_width - 0.25, abs(wpos.x));
			col = mix(col, zone_red.rgb, zone_alpha * (0.1 + 0.7 * min(edge2, 1.0)));
		}
	}
	ALBEDO = col;
	ROUGHNESS = 0.95;
}
"""


static func build(parent: Node3D, terrain: String, half_w: float, half_d: float, features: Array, scenario: Dictionary = {}) -> ShaderMaterial:
	var t: Dictionary = TERRAINS.get(terrain, TERRAINS.grass)
	# Ciel et lumière
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(t.sky_top)
	sm.sky_horizon_color = Color(t.sky_horizon)
	sm.ground_horizon_color = Color(t.sky_horizon)
	sm.ground_bottom_color = Color(t.ground)
	sky.sky_material = sm
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 0.95
	# Brouillard de profondeur : seul le décor lointain s'estompe.
	e.fog_enabled = true
	e.fog_mode = Environment.FOG_MODE_DEPTH
	e.fog_light_color = Color(t.fog)
	e.fog_depth_begin = 110.0
	e.fog_depth_end = 340.0
	e.fog_sky_affect = 0.0
	e.glow_enabled = true
	e.glow_intensity = 0.25
	e.glow_hdr_threshold = 1.2
	env.environment = e
	parent.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 140.0
	parent.add_child(sun)

	# Sol
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(600, 600)
	ground.mesh = pm
	var gm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = GROUND_SHADER
	gm.shader = sh
	gm.set_shader_parameter("c1", Color(t.ground))
	gm.set_shader_parameter("c2", Color(t.ground2))
	gm.set_shader_parameter("half_width", half_w)
	ground.material_override = gm
	parent.add_child(ground)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(600, 2, 600)
	cs.shape = bs
	cs.position = Vector3(0, -1, 0)
	body.add_child(cs)
	parent.add_child(body)

	# Décor autour du champ de bataille (hors zone de jeu).
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(terrain)
	var deco := Node3D.new()
	parent.add_child(deco)
	for i in 140:
		var x := rng.randf_range(-130, 130)
		var z := rng.randf_range(-110, 110)
		if abs(x) < half_w + 6 and abs(z) < half_d + 6:
			continue
		_tree(deco, String(t.trees), Color(t.tree_col), Vector3(x, 0, z), rng)
	# Petits éléments dans la zone (sans collision).
	for i in 40:
		var p := Vector3(rng.randf_range(-half_w, half_w), 0, rng.randf_range(-half_d, half_d))
		var c := Color(t.ground).darkened(rng.randf_range(0.1, 0.3))
		deco.add_child(Models.sphere(rng.randf_range(0.15, 0.4), Models.mat(c), p, Vector3(1.2, 0.5, 1.0)))
	for f in features:
		_feature(deco, String(f), half_w, half_d, rng)
	# Abris du scénario : sacs de sable, murets ou tranchées sur le bord avant de la zone.
	for c in scenario.get("cover", []):
		var team := int(c.get("team", 0))
		var front: float = float(c.zmin) if team == 0 else float(c.zmax)
		_cover_line(deco, String(c.get("visual", "sandbags")), front - (0.6 if team == 0 else -0.6), half_w, rng)
	if scenario.has("stakes_z"):
		var sz := float(scenario.stakes_z)
		for i in 46:
			var x := -half_w * 0.72 + i * half_w * 1.44 / 45.0
			deco.add_child(Models.cyl(0.0, 0.07, 1.5, Models.mat(Color("7a5a3a")), Vector3(x, 0.45, sz), Vector3(-0.7, 0, rng.randf_range(-0.15, 0.15))))
	return gm


static func _cover_line(parent: Node3D, visual: String, z: float, half_w: float, rng: RandomNumberGenerator) -> void:
	match visual:
		"wall":
			for i in 40:
				var x := -half_w + i * (half_w * 2) / 39.0
				parent.add_child(Models.box(Vector3(2.1, rng.randf_range(0.6, 0.8), 0.6), Models.mat(Color("8a857a").darkened(rng.randf_range(0.0, 0.2))), Vector3(x, 0.35, z), Vector3(0, rng.randf_range(-0.05, 0.05), 0)))
		"trench":
			parent.add_child(Models.box(Vector3(half_w * 2, 0.04, 2.2), Models.mat(Color("3a2e22")), Vector3(0, 0.02, z + 1.2)))
			var sand := Models.mat(Color("8f8466"), 0.95)
			for i in 34:
				var x := -half_w + i * (half_w * 2) / 33.0
				parent.add_child(Models.capsule(0.25, 1.5, sand, Vector3(x, 0.25, z), Vector3(0, rng.randf_range(-0.2, 0.2), PI / 2)))
		"none":
			pass
		_:
			var sand2 := Models.mat(Color("8f8466"), 0.95)
			for i in 34:
				var x := -half_w + i * (half_w * 2) / 33.0
				parent.add_child(Models.capsule(0.25, 1.5, sand2, Vector3(x, 0.25, z), Vector3(0, rng.randf_range(-0.2, 0.2), PI / 2)))
				parent.add_child(Models.capsule(0.23, 1.4, sand2, Vector3(x + 0.6, 0.65, z), Vector3(0, rng.randf_range(-0.2, 0.2), PI / 2)))


static func _tree(parent: Node3D, kind: String, c: Color, pos: Vector3, rng: RandomNumberGenerator) -> void:
	var trunk := Models.mat(Color("5a4030"))
	var leaf := Models.mat(c.lightened(rng.randf_range(-0.1, 0.15)))
	var s := rng.randf_range(0.8, 1.6)
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = rng.randf() * TAU
	n.scale = Vector3.ONE * s
	parent.add_child(n)
	match kind:
		"leafy":
			n.add_child(Models.cyl(0.18, 0.25, 2.6, trunk, Vector3(0, 1.3, 0)))
			n.add_child(Models.sphere(1.6, leaf, Vector3(0, 3.6, 0), Vector3(1, 0.85, 1)))
			n.add_child(Models.sphere(1.1, leaf, Vector3(0.8, 3.0, 0.3)))
		"olive":
			n.add_child(Models.cyl(0.16, 0.3, 1.8, trunk, Vector3(0, 0.9, 0), Vector3(0, 0, 0.2)))
			for k in 4:
				var a := TAU * k / 4.0 + rng.randf()
				n.add_child(Models.sphere(rng.randf_range(0.7, 1.0), leaf, Vector3(cos(a) * 0.7 + 0.2, 2.2 + rng.randf_range(-0.2, 0.4), sin(a) * 0.7), Vector3(1.0, 0.75, 1.0)))
		"pine":
			n.add_child(Models.cyl(0.15, 0.2, 1.4, trunk, Vector3(0, 0.7, 0)))
			n.add_child(Models.cyl(0.0, 1.4, 2.4, leaf, Vector3(0, 2.2, 0)))
			n.add_child(Models.cyl(0.0, 1.0, 1.8, leaf, Vector3(0, 3.4, 0)))
			n.add_child(Models.cyl(0.0, 0.9, 1.0, Models.mat(Color("f0f4f8")), Vector3(0, 3.9, 0)))
		"dead":
			n.add_child(Models.cyl(0.08, 0.22, 3.2, trunk, Vector3(0, 1.6, 0)))
			n.add_child(Models.cyl(0.04, 0.08, 1.4, trunk, Vector3(0.4, 2.6, 0), Vector3(0, 0, -0.8)))
			n.add_child(Models.cyl(0.04, 0.08, 1.0, trunk, Vector3(-0.3, 2.2, 0), Vector3(0, 0, 0.9)))
		"palm":
			n.add_child(Models.cyl(0.14, 0.2, 4.2, trunk, Vector3(0, 2.1, 0), Vector3(0, 0, 0.12)))
			for i in 6:
				var ang := TAU * i / 6.0
				n.add_child(Models.box(Vector3(0.5, 0.05, 2.2), leaf, Vector3(sin(ang) * 0.9 + 0.25, 4.0, cos(ang) * 0.9), Vector3(0.45, ang, 0)))
			n.add_child(Models.sphere(1.3, Models.mat(c.darkened(0.1)), Vector3(0, 0.6, 0), Vector3(1.4, 0.5, 1.4)))
		"rock":
			n.add_child(Models.sphere(rng.randf_range(0.6, 1.6), leaf, Vector3(0, 0.2, 0), Vector3(1.3, 0.7, 1.0)))


static func _feature(parent: Node3D, f: String, half_w: float, half_d: float, rng: RandomNumberGenerator) -> void:
	match f:
		"craters":
			for i in 30:
				var p := Vector3(rng.randf_range(-half_w, half_w), 0.02, rng.randf_range(-half_d, half_d))
				var r := rng.randf_range(0.8, 2.2)
				parent.add_child(Models.cyl(r, r * 0.8, 0.04, Models.mat(Color(0.2, 0.16, 0.12)), p))
				parent.add_child(Models.torus(r * 0.8, r * 1.15, Models.mat(Color(0.33, 0.27, 0.2)), p + Vector3(0, 0.05, 0)))
		"wire":
			for z in [-half_d * 0.35, half_d * 0.35]:
				for i in 18:
					var x := -half_w + 2 + i * (half_w * 2 - 4) / 17.0
					var post := Models.cyl(0.05, 0.05, 1.1, Models.mat(Color("5a4030")), Vector3(x, 0.55, z), Vector3(0, 0, rng.randf_range(-0.2, 0.2)))
					parent.add_child(post)
					if i < 17:
						parent.add_child(Models.torus(0.3, 0.33, Models.metal_mat(Color("5a5a5a")), Vector3(x + 1.2, 0.5, z), Vector3(0, 0, PI / 2)))
		"trench_blue", "trench_red":
			var z := half_d * 0.8 if f == "trench_blue" else -half_d * 0.8
			var sand := Models.mat(Color("8f8466"), 0.95)
			for i in 30:
				var x := -half_w + i * (half_w * 2) / 29.0
				parent.add_child(Models.capsule(0.25, 1.6, sand, Vector3(x, 0.25, z - sign(z) * 1.5), Vector3(0, 0, PI / 2)))
		"stakes":
			for i in 40:
				var x := -half_w * 0.7 + i * half_w * 1.4 / 39.0
				parent.add_child(Models.cyl(0.0, 0.06, 1.4, Models.mat(Color("7a5a3a")), Vector3(x, 0.5, half_d * 0.18), Vector3(-0.6, 0, 0)))
		"woods_sides":
			for side in [-1.0, 1.0]:
				for i in 40:
					var p := Vector3(side * rng.randf_range(half_w + 1, half_w + 14), 0, rng.randf_range(-half_d, half_d))
					_tree(parent, "leafy", Color("3f6a2a"), p, rng)
		"village":
			for i in 6:
				var p := Vector3(rng.randf_range(-half_w, half_w) * 0.8, 0, rng.randf_range(-half_d, -half_d * 0.5) if i % 2 else rng.randf_range(half_d * 0.6, half_d))
				var house := Node3D.new()
				house.position = Vector3(sign(p.x) * (half_w + rng.randf_range(4, 14)), 0, p.z)
				house.rotation.y = rng.randf() * TAU
				parent.add_child(house)
				house.add_child(Models.box(Vector3(5, 3, 4), Models.mat(Color("d8cdb0")), Vector3(0, 1.5, 0)))
				house.add_child(Models.prism(Vector3(5.4, 1.6, 4.4), Models.mat(Color("8a3a2a")), Vector3(0, 3.8, 0)))
		"hills":
			for i in 8:
				var p := Vector3(rng.randf_range(-120, 120), -6, rng.randf_range(-120, -60))
				parent.add_child(Models.sphere(rng.randf_range(18, 35), Models.mat(Color("5f7a3a").darkened(0.15)), p, Vector3(1.6, 0.6, 1.2)))
