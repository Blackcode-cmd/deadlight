extends Camera3D

var target: Node3D
var follow_distance := 9.5
var follow_height := 12.0
var look_height := 0.75
var follow_smoothing := 7.5

func _ready() -> void:
    top_level = true
    physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

func snap_to_target() -> void:
    if target == null:
        return
    var t := target.global_transform
    var behind := t.basis.z.normalized()
    global_position = t.origin + behind * follow_distance + Vector3.UP * follow_height
    look_at(t.origin + Vector3.UP * look_height, Vector3.UP)

func _process(delta: float) -> void:
    if target == null:
        return

    var t := target.get_global_transform_interpolated()
    var behind := t.basis.z.normalized()
    var desired_position := t.origin + behind * follow_distance + Vector3.UP * follow_height
    var weight := 1.0 - exp(-follow_smoothing * delta)
    global_position = global_position.lerp(desired_position, weight)
    look_at(t.origin + Vector3.UP * look_height, Vector3.UP)
