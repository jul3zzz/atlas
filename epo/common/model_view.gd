class_name ModelView
extends SubViewportContainer
## Petite vue 3D intégrée à l'interface : affiche un modèle qui tourne (glisser pour le faire pivoter).

var vp: SubViewport
var pivot: Node3D
var cam: Camera3D
var model: Node3D
var auto_rotate := 0.45
var frame_height := 2.0
var _drag := false
var _t := 0.0


func _init() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	vp = SubViewport.new()
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	add_child(vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.78, 0.7)
	e.ambient_light_energy = 0.4
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -40, 0)
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	vp.add_child(sun)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-15, 150, 0)
	rim.light_energy = 0.6
	rim.light_color = Color(1.0, 0.85, 0.6)
	vp.add_child(rim)
	pivot = Node3D.new()
	pivot.rotation.y = PI + 0.5
	vp.add_child(pivot)
	var base := Models.cyl(1.1, 1.15, 0.08, Models.mat(Color("1a1f13"), 0.9), Vector3(0, -0.04, 0), Vector3.ZERO, 32)
	vp.add_child(base)
	cam = Camera3D.new()
	cam.fov = 32.0
	vp.add_child(cam)
	cam.current = true
	_frame()
	if model and model.get_parent() == null:
		pivot.add_child(model)


func set_model(n: Node3D, height := 2.0) -> void:
	if model and is_instance_valid(model):
		model.queue_free()
	model = n
	frame_height = height
	if pivot:
		pivot.add_child(n)
		_frame()


func _frame() -> void:
	if cam == null:
		return
	var h := frame_height
	cam.position = Vector3(0, h * 0.62, h * 3.1)
	cam.look_at(Vector3(0, h * 0.48, 0))


func _process(delta: float) -> void:
	_t += delta
	if pivot and not _drag:
		pivot.rotation.y += auto_rotate * delta
	if model is SoldierModel:
		model.animate(delta, 0.0, sin(_t * 0.6) > 0.4)
	elif model is VehicleModel:
		model.animate(delta, 0.0, false)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_drag = event.pressed
	elif event is InputEventMouseMotion and _drag and pivot:
		pivot.rotation.y += event.relative.x * 0.01
