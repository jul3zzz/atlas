class_name RtsCamera
extends Node3D
## Caméra de stratégie : clic droit = tourner, molette = zoom,
## ZQSD/WASD/flèches = déplacer, clic molette = glisser, Maj = plus vite.
## Fonctionne même au ralenti (utilise le temps réel).

var cam: Camera3D
var yaw := 0.0
var pitch := -0.85
var dist := 42.0
var target := Vector3(0, 0, 10)
var min_dist := 5.0
var max_dist := 130.0
var bounds := AABB(Vector3(-60, 0, -50), Vector3(120, 0, 100))
var follow: Node3D = null
var auto_orbit := 0.0
var input_enabled := true

var _yaw := 0.0
var _pitch := -0.85
var _dist := 42.0
var _target := Vector3.ZERO
var _rotating := false
var _panning := false
var _shake := 0.0
var _last_usec := 0


func _ready() -> void:
	cam = Camera3D.new()
	cam.fov = 55.0
	cam.near = 0.1
	cam.far = 900.0
	add_child(cam)
	cam.current = true
	_yaw = yaw
	_pitch = pitch
	_dist = dist
	_target = target
	_last_usec = Time.get_ticks_usec()
	_update_transform()


func snap() -> void:
	_yaw = yaw
	_pitch = pitch
	_dist = dist
	_target = target
	_update_transform()


func shake(amount: float, from: Vector3 = Vector3.INF) -> void:
	var k := 1.0
	if from != Vector3.INF and cam:
		k = clamp(1.0 - cam.global_position.distance_to(from) / 120.0, 0.15, 1.0)
	_shake = min(1.5, _shake + amount * k)


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					dist = clamp(dist * 0.88, min_dist, max_dist)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					dist = clamp(dist * 1.12, min_dist, max_dist)
			MOUSE_BUTTON_RIGHT:
				_rotating = event.pressed
			MOUSE_BUTTON_MIDDLE:
				_panning = event.pressed
	elif event is InputEventMouseMotion:
		if _rotating:
			yaw -= event.relative.x * 0.006
			pitch = clamp(pitch - event.relative.y * 0.005, -1.45, -0.12)
		elif _panning:
			var right := Vector3(cos(yaw), 0, -sin(yaw))
			var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
			var k := dist * 0.0022
			target += (-right * event.relative.x + fwd * event.relative.y) * k
			follow = null


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var dt: float = clamp((now - _last_usec) / 1000000.0, 0.0, 0.1)
	_last_usec = now
	if input_enabled:
		var mv := Input.get_vector("cam_left", "cam_right", "cam_forward", "cam_back")
		if mv.length() > 0.0:
			follow = null
			var right := Vector3(cos(yaw), 0, -sin(yaw))
			var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
			var spd := (12.0 + dist * 0.8) * (2.5 if Input.is_action_pressed("cam_fast") else 1.0)
			target += (right * mv.x - fwd * mv.y) * spd * dt
	if follow and is_instance_valid(follow):
		target = follow.global_position
	elif follow:
		follow = null
	yaw += auto_orbit * dt
	target.x = clamp(target.x, bounds.position.x, bounds.end.x)
	target.z = clamp(target.z, bounds.position.z, bounds.end.z)
	var k: float = clamp(dt * 8.0, 0.0, 1.0)
	_yaw = lerp_angle(_yaw, yaw, k)
	_pitch = lerpf(_pitch, pitch, k)
	_dist = lerpf(_dist, dist, k)
	_target = _target.lerp(target, k)
	_shake = move_toward(_shake, 0.0, dt * 2.5)
	_update_transform()


func _update_transform() -> void:
	if cam == null:
		return
	var b := Basis(Vector3.UP, _yaw) * Basis(Vector3.RIGHT, _pitch)
	var pos := _target + b * Vector3(0, 0, _dist)
	if pos.y < 1.5:
		pos.y = 1.5
	var jitter := Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * _shake * 0.35
	cam.global_position = pos + jitter
	cam.look_at(_target + Vector3(0, 1.0, 0) + jitter * 0.5, Vector3.UP)


## Rayon souris -> point au sol (y = 0). Renvoie Vector3.INF si raté.
func mouse_ground(mouse_pos: Vector2) -> Vector3:
	var from := cam.project_ray_origin(mouse_pos)
	var dir := cam.project_ray_normal(mouse_pos)
	if abs(dir.y) < 0.0001:
		return Vector3.INF
	var t := -from.y / dir.y
	if t < 0:
		return Vector3.INF
	return from + dir * t
