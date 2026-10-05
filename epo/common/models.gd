class_name Models
extends RefCounted
## Fabrique de modèles 3D « low-poly » construits à partir de formes simples.
## Aucun fichier 3D externe : soldats, coiffes, armes, montures et véhicules sont générés ici.

static var _mats: Dictionary = {}
static var _meshes: Dictionary = {}


# --- Matériaux et primitives ------------------------------------------------------

static func mat(color: Color, rough := 0.85, metal := 0.0, emit := 0.0) -> StandardMaterial3D:
	var key := "%s|%.2f|%.2f|%.2f" % [color.to_html(), rough, metal, emit]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emit
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mats[key] = m
	return m


static func metal_mat(color: Color) -> StandardMaterial3D:
	return mat(color, 0.38, 0.75)


static func _mesh(key: String, maker: Callable) -> Mesh:
	if not _meshes.has(key):
		_meshes[key] = maker.call()
	return _meshes[key]


static func mi(mesh: Mesh, material: Material, pos := Vector3.ZERO, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = material
	m.position = pos
	m.rotation = rot
	m.scale = scl
	return m


static func box(size: Vector3, material: Material, pos := Vector3.ZERO, rot := Vector3.ZERO) -> MeshInstance3D:
	var mesh := _mesh("box%v" % size, func():
		var b := BoxMesh.new()
		b.size = size
		return b)
	return mi(mesh, material, pos, rot)


static func cyl(r_top: float, r_bot: float, h: float, material: Material, pos := Vector3.ZERO, rot := Vector3.ZERO, segs := 12) -> MeshInstance3D:
	var mesh := _mesh("cyl%.3f_%.3f_%.3f_%d" % [r_top, r_bot, h, segs], func():
		var c := CylinderMesh.new()
		c.top_radius = r_top
		c.bottom_radius = r_bot
		c.height = h
		c.radial_segments = segs
		c.rings = 1
		return c)
	return mi(mesh, material, pos, rot)


static func sphere(r: float, material: Material, pos := Vector3.ZERO, scl := Vector3.ONE, hemi := false) -> MeshInstance3D:
	var mesh := _mesh("sph%.3f_%s" % [r, hemi], func():
		var s := SphereMesh.new()
		s.radius = r
		s.height = r if hemi else r * 2.0
		s.is_hemisphere = hemi
		s.radial_segments = 14
		s.rings = 7
		return s)
	return mi(mesh, material, pos, Vector3.ZERO, scl)


static func capsule(r: float, h: float, material: Material, pos := Vector3.ZERO, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mesh := _mesh("cap%.3f_%.3f" % [r, h], func():
		var c := CapsuleMesh.new()
		c.radius = r
		c.height = max(h, r * 2.0)
		c.radial_segments = 12
		c.rings = 4
		return c)
	return mi(mesh, material, pos, rot, scl)


static func torus(inner: float, outer: float, material: Material, pos := Vector3.ZERO, rot := Vector3.ZERO) -> MeshInstance3D:
	var mesh := _mesh("tor%.3f_%.3f" % [inner, outer], func():
		var t := TorusMesh.new()
		t.inner_radius = inner
		t.outer_radius = outer
		t.rings = 16
		t.ring_segments = 6
		return t)
	return mi(mesh, material, pos, rot)


static func prism(size: Vector3, material: Material, pos := Vector3.ZERO, rot := Vector3.ZERO) -> MeshInstance3D:
	var mesh := _mesh("pri%v" % size, func():
		var p := PrismMesh.new()
		p.size = size
		return p)
	return mi(mesh, material, pos, rot)


static func col(v, fallback := Color.GRAY) -> Color:
	if v is Color:
		return v
	if v is String and v != "":
		return Color(v)
	return fallback


# --- Soldat ---------------------------------------------------------------------

const SKINS := ["f1c9a5", "e0ac7e", "c68b59", "8d5a3b", "5c3a24"]


## cfg : uniform, pants, trim, boots, skin (0-4), headgear, helmet, weapon, shield,
##       team (Color), mount ("horse"), pack (bool), scale
static func soldier(cfg: Dictionary) -> SoldierModel:
	var s := SoldierModel.new()
	s.build(cfg)
	return s


static func headgear(kind: String, c: Color, accent: Color) -> Node3D:
	var n := Node3D.new()
	var m := mat(c, 0.7)
	var mm := metal_mat(c)
	var a := mat(accent, 0.8)
	var dark := mat(Color("1d1a14"))
	match kind:
		"hair":
			n.add_child(sphere(0.215, mat(c), Vector3(0, 0.05, 0.02), Vector3(1.0, 0.75, 1.0), true))
		"galea":
			n.add_child(sphere(0.23, mm, Vector3(0, 0.02, 0), Vector3(1, 1, 1), true))
			n.add_child(box(Vector3(0.05, 0.16, 0.36), a, Vector3(0, 0.29, 0.02)))
			n.add_child(box(Vector3(0.04, 0.14, 0.12), mm, Vector3(0.21, -0.07, -0.05)))
			n.add_child(box(Vector3(0.04, 0.14, 0.12), mm, Vector3(-0.21, -0.07, -0.05)))
			n.add_child(box(Vector3(0.36, 0.06, 0.08), mm, Vector3(0, -0.04, 0.2)))
		"hoplite":
			n.add_child(sphere(0.235, mm, Vector3(0, -0.02, 0), Vector3(1, 1.25, 1.05), true))
			n.add_child(box(Vector3(0.44, 0.12, 0.05), a, Vector3(0, 0.33, 0)))
			n.add_child(box(Vector3(0.08, 0.2, 0.04), dark, Vector3(0.07, -0.03, -0.23)))
			n.add_child(box(Vector3(0.08, 0.2, 0.04), dark, Vector3(-0.07, -0.03, -0.23)))
		"nemes":
			n.add_child(sphere(0.225, m, Vector3(0, 0.02, 0.01), Vector3(1.05, 0.95, 1.05), true))
			n.add_child(box(Vector3(0.14, 0.3, 0.06), m, Vector3(0.2, -0.15, -0.02)))
			n.add_child(box(Vector3(0.14, 0.3, 0.06), m, Vector3(-0.2, -0.15, -0.02)))
			n.add_child(torus(0.21, 0.24, a, Vector3(0, 0.03, 0)))
		"gaul":
			n.add_child(sphere(0.225, mm, Vector3(0, 0.02, 0), Vector3(1, 1.05, 1), true))
			n.add_child(sphere(0.05, mm, Vector3(0, 0.26, 0)))
			n.add_child(cyl(0.25, 0.25, 0.03, mm, Vector3(0, 0.01, 0)))
		"nasal":
			n.add_child(cyl(0.02, 0.23, 0.32, mm, Vector3(0, 0.15, 0)))
			n.add_child(box(Vector3(0.04, 0.18, 0.03), mm, Vector3(0, -0.04, -0.22)))
		"great_helm":
			n.add_child(cyl(0.235, 0.235, 0.42, mm, Vector3(0, 0.02, 0)))
			n.add_child(cyl(0.0, 0.235, 0.06, mm, Vector3(0, 0.26, 0)))
			n.add_child(box(Vector3(0.36, 0.035, 0.03), dark, Vector3(0, 0.05, -0.23)))
			n.add_child(box(Vector3(0.025, 0.25, 0.02), a, Vector3(0, -0.02, -0.24)))
		"kettle":
			n.add_child(sphere(0.22, mm, Vector3(0, 0.03, 0), Vector3(1, 1, 1), true))
			n.add_child(cyl(0.36, 0.36, 0.025, mm, Vector3(0, 0.03, 0), Vector3(0.1, 0, 0), 16))
		"morion":
			n.add_child(sphere(0.22, mm, Vector3(0, 0.04, 0), Vector3(1, 1.2, 1.1), true))
			n.add_child(box(Vector3(0.03, 0.14, 0.4), mm, Vector3(0, 0.3, 0)))
			n.add_child(cyl(0.34, 0.3, 0.03, mm, Vector3(0, 0.04, 0), Vector3.ZERO, 16))
		"musketeer":
			n.add_child(cyl(0.38, 0.38, 0.025, m, Vector3(0, 0.12, 0), Vector3(0.0, 0, 0.15), 16))
			n.add_child(cyl(0.17, 0.2, 0.2, m, Vector3(0, 0.22, 0)))
			n.add_child(capsule(0.04, 0.5, a, Vector3(0.14, 0.32, 0.1), Vector3(0.4, 0, -1.0)))
		"tricorne":
			n.add_child(cyl(0.18, 0.2, 0.16, m, Vector3(0, 0.2, 0)))
			for i in 3:
				var ang := TAU * i / 3.0 + PI
				var p := box(Vector3(0.36, 0.12, 0.03), m, Vector3(sin(ang) * 0.19, 0.17, cos(ang) * 0.19), Vector3(-0.4, ang, 0))
				n.add_child(p)
			n.add_child(torus(0.17, 0.2, a, Vector3(0, 0.12, 0)))
		"bicorne":
			n.add_child(cyl(0.2, 0.2, 0.62, m, Vector3(0, 0.22, 0), Vector3(0, 0, PI / 2), 14))
			n.add_child(box(Vector3(0.66, 0.2, 0.2), m, Vector3(0, 0.15, 0)))
			n.add_child(sphere(0.06, a, Vector3(0.0, 0.3, -0.1)))
		"shako":
			n.add_child(cyl(0.24, 0.2, 0.38, m, Vector3(0, 0.25, 0)))
			n.add_child(cyl(0.245, 0.245, 0.04, a, Vector3(0, 0.43, 0)))
			n.add_child(box(Vector3(0.3, 0.025, 0.14), dark, Vector3(0, 0.07, -0.2), Vector3(0.3, 0, 0)))
			n.add_child(capsule(0.045, 0.24, a, Vector3(0, 0.56, -0.08)))
			n.add_child(sphere(0.05, metal_mat(Color("d6b13f")), Vector3(0, 0.28, -0.23)))
		"kepi":
			n.add_child(cyl(0.2, 0.22, 0.2, m, Vector3(0, 0.15, 0.02), Vector3(-0.12, 0, 0)))
			n.add_child(cyl(0.225, 0.225, 0.06, a, Vector3(0, 0.09, 0.01)))
			n.add_child(box(Vector3(0.28, 0.02, 0.13), dark, Vector3(0, 0.07, -0.21), Vector3(0.25, 0, 0)))
		"pickelhaube":
			n.add_child(sphere(0.225, m, Vector3(0, 0.04, 0), Vector3(1, 1.15, 1.1), true))
			n.add_child(cyl(0.0, 0.035, 0.16, metal_mat(Color("c9b15a")), Vector3(0, 0.33, 0)))
			n.add_child(box(Vector3(0.3, 0.02, 0.12), m, Vector3(0, 0.05, -0.2), Vector3(0.2, 0, 0)))
		"adrian":
			n.add_child(sphere(0.225, m, Vector3(0, 0.04, 0), Vector3(1, 0.95, 1.1), true))
			n.add_child(cyl(0.3, 0.3, 0.02, m, Vector3(0, 0.04, 0.0), Vector3(0.12, 0, 0), 16))
			n.add_child(box(Vector3(0.04, 0.07, 0.42), m, Vector3(0, 0.24, 0)))
		"brodie":
			n.add_child(sphere(0.21, m, Vector3(0, 0.07, 0), Vector3(1, 0.7, 1), true))
			n.add_child(cyl(0.34, 0.32, 0.04, m, Vector3(0, 0.07, 0), Vector3.ZERO, 16))
		"stahlhelm":
			n.add_child(sphere(0.23, m, Vector3(0, 0.02, 0), Vector3(1, 1.05, 1.1), true))
			n.add_child(cyl(0.235, 0.29, 0.12, m, Vector3(0, -0.04, 0.02), Vector3.ZERO, 16))
		"m1":
			n.add_child(sphere(0.235, m, Vector3(0, 0.0, 0), Vector3(1.05, 1.0, 1.1), true))
			n.add_child(cyl(0.265, 0.27, 0.05, m, Vector3(0, 0.0, 0), Vector3(0.08, 0, 0), 16))
			n.add_child(cyl(0.012, 0.012, 0.42, dark, Vector3(0, -0.12, -0.05), Vector3(0, 0, PI / 2)))
		"ssh40":
			n.add_child(sphere(0.23, m, Vector3(0, 0.02, 0), Vector3(1, 1.08, 1.1), true))
			n.add_child(cyl(0.24, 0.27, 0.06, m, Vector3(0, 0.0, 0), Vector3.ZERO, 16))
			n.add_child(sphere(0.035, mat(Color("c0262d"), 0.5), Vector3(0, 0.12, -0.22)))
		"pilotka":
			n.add_child(box(Vector3(0.2, 0.12, 0.38), m, Vector3(0.03, 0.18, 0.0), Vector3(0, 0, -0.15)))
			n.add_child(sphere(0.03, mat(Color("c0262d"), 0.5), Vector3(0.03, 0.18, -0.19)))
		"ushanka":
			n.add_child(cyl(0.25, 0.26, 0.24, m, Vector3(0, 0.17, 0)))
			n.add_child(box(Vector3(0.07, 0.22, 0.2), m, Vector3(0.24, -0.02, 0.0)))
			n.add_child(box(Vector3(0.07, 0.22, 0.2), m, Vector3(-0.24, -0.02, 0.0)))
			n.add_child(box(Vector3(0.36, 0.1, 0.06), m, Vector3(0, 0.12, -0.24)))
			n.add_child(sphere(0.035, mat(Color("c0262d"), 0.5), Vector3(0, 0.14, -0.28)))
		"beret":
			n.add_child(cyl(0.23, 0.2, 0.08, m, Vector3(0.05, 0.16, 0.02), Vector3(0.05, 0, -0.35), 16))
			n.add_child(sphere(0.03, metal_mat(Color("d6b13f")), Vector3(-0.12, 0.12, -0.17)))
		"boonie":
			n.add_child(cyl(0.2, 0.22, 0.15, m, Vector3(0, 0.15, 0)))
			n.add_child(cyl(0.36, 0.36, 0.025, m, Vector3(0, 0.08, 0), Vector3(0.06, 0, 0.04), 16))
		"modern":
			n.add_child(sphere(0.24, m, Vector3(0, 0.01, 0), Vector3(1.05, 1.0, 1.08), true))
			n.add_child(box(Vector3(0.1, 0.07, 0.05), dark, Vector3(0, 0.1, -0.24)))
			n.add_child(box(Vector3(0.3, 0.07, 0.06), mat(Color("2b3a3f"), 0.2, 0.3), Vector3(0, 0.0, -0.23)))
			n.add_child(torus(0.22, 0.25, dark, Vector3(0, 0.0, 0.0)))
		"keffiyeh":
			n.add_child(sphere(0.23, m, Vector3(0, 0.0, 0.01), Vector3(1.05, 1.0, 1.05), true))
			n.add_child(box(Vector3(0.44, 0.34, 0.08), m, Vector3(0, -0.15, 0.13)))
			n.add_child(torus(0.21, 0.24, dark, Vector3(0, 0.07, 0)))
		"bearskin":
			n.add_child(cyl(0.2, 0.25, 0.62, m, Vector3(0, 0.28, 0.02), Vector3.ZERO, 14))
			n.add_child(sphere(0.2, m, Vector3(0, 0.58, 0.02), Vector3(1, 0.5, 1)))
			n.add_child(capsule(0.035, 0.3, a, Vector3(0.19, 0.42, 0.0), Vector3(0, 0, -0.1)))
			n.add_child(torus(0.06, 0.09, a, Vector3(-0.18, 0.2, 0.05), Vector3(0, 0, PI / 2)))
		"non_la":
			n.add_child(cyl(0.0, 0.42, 0.26, m, Vector3(0, 0.22, 0), Vector3.ZERO, 16))
			n.add_child(cyl(0.006, 0.006, 0.36, mat(Color("3a2a1a")), Vector3(0, -0.06, -0.12), Vector3(0.3, 0, PI / 2)))
		"crown":
			n.add_child(cyl(0.2, 0.2, 0.12, metal_mat(Color("d6b13f")), Vector3(0, 0.18, 0)))
			for i in 5:
				var ang := TAU * i / 5.0
				n.add_child(prism(Vector3(0.08, 0.1, 0.03), metal_mat(Color("d6b13f")), Vector3(sin(ang) * 0.19, 0.28, cos(ang) * 0.19), Vector3(0, ang, 0)))
		_:
			pass
	return n


## Armes tenues en main. Axe principal : -Y dans l'espace du bras (le prolongement du bras).
static func hand_weapon(kind: String) -> Node3D:
	var n := Node3D.new()
	var steel := metal_mat(Color("b9bec4"))
	var dark_steel := metal_mat(Color("3a3d40"))
	var wood := mat(Color("6b4423"), 0.8)
	var light_wood := mat(Color("a07040"), 0.8)
	var black := mat(Color("1e1f1d"), 0.6)
	var brass := metal_mat(Color("c9a33a"))
	var green := mat(Color("4b5a32"), 0.7)
	# Pour les armes d'épaule : la crosse est vers le coude (+Y), le canon part vers -Y.
	match kind:
		"gladius":
			n.add_child(box(Vector3(0.055, 0.5, 0.012), steel, Vector3(0, 0, -0.32), Vector3(PI / 2, 0, 0)))
			n.add_child(box(Vector3(0.12, 0.03, 0.04), brass, Vector3(0, 0, -0.05)))
		"sword", "sabre":
			n.add_child(box(Vector3(0.045, 0.8, 0.012), steel, Vector3(0, 0.0, -0.45), Vector3(PI / 2, 0, 0)))
			n.add_child(box(Vector3(0.22, 0.03, 0.04), brass if kind == "sabre" else dark_steel, Vector3(0, 0, -0.05)))
		"axe":
			n.add_child(cyl(0.025, 0.025, 0.8, wood, Vector3(0, 0, -0.25), Vector3(PI / 2, 0, 0)))
			n.add_child(box(Vector3(0.03, 0.2, 0.18), steel, Vector3(0, 0.08, -0.58)))
		"mace":
			n.add_child(cyl(0.025, 0.025, 0.6, wood, Vector3(0, 0, -0.2), Vector3(PI / 2, 0, 0)))
			n.add_child(sphere(0.08, dark_steel, Vector3(0, 0, -0.52)))
		"spear", "pilum", "lance", "pike", "halberd":
			var length: float = {"spear": 2.2, "pilum": 1.9, "lance": 3.0, "pike": 4.5, "halberd": 2.2}[kind]
			n.add_child(cyl(0.022, 0.022, length, wood, Vector3(0, 0, -length * 0.3), Vector3(PI / 2, 0, 0)))
			n.add_child(cyl(0.0, 0.045, 0.22, steel, Vector3(0, 0, -length * 0.8 - 0.1), Vector3(-PI / 2, 0, 0)))
			if kind == "halberd":
				n.add_child(box(Vector3(0.02, 0.22, 0.16), steel, Vector3(0, 0.1, -length * 0.75)))
			if kind == "lance":
				n.add_child(cyl(0.07, 0.03, 0.25, mat(Color("8a2a2a")), Vector3(0, 0, 0.1), Vector3(PI / 2, 0, 0)))
		"bow", "longbow":
			var h := 1.0 if kind == "bow" else 1.7
			# Arc tenu verticalement dans la main gauche (axe -Z du bras = vers le haut bras tendu).
			n.add_child(capsule(0.025, h, light_wood, Vector3(0, -0.04, 0), Vector3(PI / 2, 0, 0)))
			n.add_child(cyl(0.004, 0.004, h - 0.05, mat(Color("e8e0c8")), Vector3(0, 0.08, 0), Vector3(PI / 2, 0, 0)))
		"crossbow":
			n.add_child(box(Vector3(0.07, 0.07, 0.75), wood, Vector3(0, 0, -0.3)))
			n.add_child(box(Vector3(0.7, 0.04, 0.05), dark_steel, Vector3(0, 0, -0.62)))
		"sling":
			n.add_child(cyl(0.006, 0.006, 0.5, mat(Color("8a7350")), Vector3(0, -0.25, 0)))
		"torch":
			n.add_child(cyl(0.03, 0.025, 0.5, wood, Vector3(0, 0, -0.15), Vector3(PI / 2, 0, 0)))
			n.add_child(sphere(0.07, mat(Color("ff9a2e"), 0.5, 0.0, 3.0), Vector3(0, 0, -0.42)))
		"flag":
			n.add_child(cyl(0.02, 0.02, 2.4, wood, Vector3(0, 0, 0.0), Vector3(0, 0, 0)))
			n.add_child(box(Vector3(0.02, 0.5, 0.7), mat(Color("c23a3a")), Vector3(0, 0.9, -0.36)))
		"drum":
			n.add_child(cyl(0.18, 0.18, 0.22, mat(Color("2f4f8a")), Vector3(0.0, 0.1, -0.2)))
		"pistol":
			n.add_child(box(Vector3(0.04, 0.12, 0.05), black, Vector3(0, 0.04, 0)))
			n.add_child(box(Vector3(0.035, 0.04, 0.22), black, Vector3(0, -0.02, -0.1)))
		"arquebus", "musket", "musket_bayonet", "flintlock", "rifle", "rifle_bayonet", "garand", "ak", "m16", "famas", "smg", "mg", "fal", "bazooka", "rpg", "sniper":
			_long_gun(n, kind, wood, steel, dark_steel, black, brass, green)
		"binoculars":
			n.add_child(cyl(0.035, 0.035, 0.14, black, Vector3(0.04, 0, -0.05), Vector3(PI / 2, 0, 0)))
			n.add_child(cyl(0.035, 0.035, 0.14, black, Vector3(-0.04, 0, -0.05), Vector3(PI / 2, 0, 0)))
		"tablet":
			n.add_child(box(Vector3(0.22, 0.02, 0.16), black, Vector3(0, 0, -0.1)))
			n.add_child(box(Vector3(0.2, 0.005, 0.14), mat(Color("4fd1ff"), 0.4, 0.0, 1.5), Vector3(0, 0.012, -0.1)))
		_:
			pass
	return n


## Armes d'épaule : le long de -Y du bras droit (bras tendu vers l'avant).
static func _long_gun(n: Node3D, kind: String, wood, steel, dark_steel, black, brass, green) -> void:
	var g := Node3D.new()
	# Tourné pour que le canon suive le bras (-Y), crosse vers l'épaule.
	g.rotation = Vector3(-PI / 2, 0, 0)
	g.position = Vector3(0, 0.0, 0)
	n.add_child(g)
	# Dans g : canon vers -Z... après rotation, -Z local devient -Y du bras.
	match kind:
		"arquebus", "musket", "musket_bayonet", "flintlock":
			var long := 1.5 if kind != "arquebus" else 1.25
			g.add_child(box(Vector3(0.06, 0.09, long * 0.75), wood, Vector3(0, 0, -long * 0.2)))
			g.add_child(cyl(0.017, 0.02, long * 0.6, dark_steel, Vector3(0, 0.045, -long * 0.42), Vector3(PI / 2, 0, 0)))
			g.add_child(box(Vector3(0.07, 0.16, 0.3), wood, Vector3(0, -0.04, 0.32)))
			if kind != "arquebus":
				g.add_child(box(Vector3(0.015, 0.06, 0.08), dark_steel, Vector3(0.04, 0.06, 0.05)))
			if kind == "musket_bayonet":
				g.add_child(cyl(0.0, 0.012, 0.45, steel, Vector3(0, 0.07, -long * 0.75 - 0.2), Vector3(-PI / 2, 0, 0)))
		"rifle", "rifle_bayonet", "garand", "sniper":
			g.add_child(box(Vector3(0.055, 0.08, 0.85), wood, Vector3(0, 0, -0.1)))
			g.add_child(box(Vector3(0.06, 0.15, 0.28), wood, Vector3(0, -0.04, 0.42)))
			g.add_child(cyl(0.014, 0.016, 0.55, dark_steel, Vector3(0, 0.04, -0.62), Vector3(PI / 2, 0, 0)))
			g.add_child(box(Vector3(0.05, 0.05, 0.2), dark_steel, Vector3(0, 0.05, 0.12)))
			if kind == "rifle_bayonet":
				g.add_child(cyl(0.0, 0.012, 0.5, steel, Vector3(0, 0.06, -1.1), Vector3(-PI / 2, 0, 0)))
			if kind == "sniper":
				g.add_child(cyl(0.025, 0.025, 0.3, black, Vector3(0, 0.12, 0.0), Vector3(PI / 2, 0, 0)))
		"ak":
			g.add_child(box(Vector3(0.05, 0.08, 0.32), dark_steel, Vector3(0, 0.02, 0.0)))
			g.add_child(box(Vector3(0.055, 0.06, 0.2), wood, Vector3(0, 0.0, -0.25)))
			g.add_child(cyl(0.013, 0.015, 0.3, dark_steel, Vector3(0, 0.03, -0.5), Vector3(PI / 2, 0, 0)))
			g.add_child(cyl(0.015, 0.015, 0.22, dark_steel, Vector3(0, 0.065, -0.3), Vector3(PI / 2, 0, 0)))
			g.add_child(box(Vector3(0.05, 0.13, 0.3), wood, Vector3(0, -0.03, 0.3), Vector3(-0.15, 0, 0)))
			g.add_child(box(Vector3(0.035, 0.2, 0.08), dark_steel, Vector3(0, -0.13, -0.08), Vector3(-0.35, 0, 0)))
			g.add_child(box(Vector3(0.035, 0.1, 0.05), wood, Vector3(0, -0.08, 0.1), Vector3(0.3, 0, 0)))
		"m16", "famas", "fal":
			var c: Material = black if kind != "fal" else mat(Color("3b3a30"))
			g.add_child(box(Vector3(0.05, 0.1, 0.42), c, Vector3(0, 0.02, 0.0)))
			g.add_child(box(Vector3(0.05, 0.08, 0.28), c, Vector3(0, 0.0, 0.32)))
			g.add_child(cyl(0.012, 0.014, 0.35, dark_steel, Vector3(0, 0.03, -0.38), Vector3(PI / 2, 0, 0)))
			g.add_child(box(Vector3(0.03, 0.16, 0.06), dark_steel, Vector3(0, -0.11, -0.05)))
			if kind == "m16":
				g.add_child(box(Vector3(0.025, 0.07, 0.2), c, Vector3(0, 0.1, 0.02)))
			if kind == "famas":
				g.add_child(box(Vector3(0.03, 0.05, 0.45), c, Vector3(0, 0.1, -0.05)))
		"smg":
			g.add_child(box(Vector3(0.05, 0.08, 0.4), black, Vector3(0, 0.02, -0.05)))
			g.add_child(cyl(0.015, 0.015, 0.15, dark_steel, Vector3(0, 0.03, -0.32), Vector3(PI / 2, 0, 0)))
			g.add_child(box(Vector3(0.03, 0.2, 0.05), dark_steel, Vector3(0, -0.12, -0.12)))
		"mg":
			g.add_child(box(Vector3(0.08, 0.12, 0.6), black, Vector3(0, 0.02, 0.0)))
			g.add_child(cyl(0.025, 0.025, 0.6, dark_steel, Vector3(0, 0.03, -0.6), Vector3(PI / 2, 0, 0)))
			g.add_child(box(Vector3(0.06, 0.14, 0.25), wood, Vector3(0, -0.02, 0.4)))
			g.add_child(box(Vector3(0.12, 0.1, 0.1), green, Vector3(0.08, -0.06, -0.05)))
		"bazooka", "rpg":
			g.add_child(cyl(0.05, 0.05, 1.2, green if kind == "bazooka" else dark_steel, Vector3(0, 0.04, -0.2), Vector3(PI / 2, 0, 0)))
			if kind == "rpg":
				g.add_child(cyl(0.0, 0.07, 0.25, green, Vector3(0, 0.04, -0.9), Vector3(-PI / 2, 0, 0)))
				g.add_child(box(Vector3(0.05, 0.08, 0.3), wood, Vector3(0, 0.0, -0.1)))


static func shield(kind: String, c: Color, accent: Color) -> Node3D:
	var n := Node3D.new()
	var m := mat(c, 0.7)
	var a := mat(accent, 0.7)
	match kind:
		"scutum":
			n.add_child(box(Vector3(0.6, 0.95, 0.06), m))
			n.add_child(sphere(0.07, metal_mat(Color("c9a33a")), Vector3(0, 0, -0.04)))
			n.add_child(box(Vector3(0.06, 0.9, 0.02), a, Vector3(0, 0, -0.035)))
		"hoplon":
			n.add_child(cyl(0.45, 0.45, 0.06, m, Vector3.ZERO, Vector3(PI / 2, 0, 0), 18))
			n.add_child(cyl(0.2, 0.2, 0.065, a, Vector3.ZERO, Vector3(PI / 2, 0, 0), 18))
		"round":
			n.add_child(cyl(0.38, 0.38, 0.05, m, Vector3.ZERO, Vector3(PI / 2, 0, 0), 16))
			n.add_child(sphere(0.07, metal_mat(Color("8a8f94")), Vector3(0, 0, -0.03)))
		"kite", "heater":
			var h := 0.95 if kind == "kite" else 0.65
			n.add_child(box(Vector3(0.5, h * 0.6, 0.05), m, Vector3(0, h * 0.18, 0)))
			n.add_child(prism(Vector3(0.5, h * 0.45, 0.05), m, Vector3(0, -h * 0.33, 0), Vector3(0, 0, PI)))
			n.add_child(box(Vector3(0.08, h * 0.8, 0.02), a, Vector3(0, 0, -0.03)))
		"riot":
			n.add_child(box(Vector3(0.55, 0.9, 0.03), mat(Color(0.7, 0.8, 0.9, 0.5), 0.1)))
	return n


# --- Montures et véhicules -------------------------------------------------------

static func horse(c: Color) -> HorseModel:
	var h := HorseModel.new()
	h.build(c)
	return h


static func vehicle(kind: String, c: Color, accent: Color, crew_cfg: Dictionary = {}) -> VehicleModel:
	var v := VehicleModel.new()
	v.build(kind, c, accent, crew_cfg)
	return v
