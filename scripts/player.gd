extends CharacterBody3D

var walk_speed := 4.3
var sprint_speed := 7.2
var turn_rate := deg_to_rad(150.0)
var turn_smoothing := 9.0
var enabled := false
var world: Node
var target_yaw := 0.0

func _ready() -> void:
    target_yaw = rotation.y

func _physics_process(delta: float) -> void:
    if not enabled:
        velocity = Vector3.ZERO
        return

    var turn_axis := Input.get_axis("turn_left", "turn_right")
    if abs(turn_axis) > 0.001:
        target_yaw = wrapf(target_yaw + turn_axis * turn_rate * delta, -PI, PI)

    if Input.is_action_just_pressed("turn_around"):
        request_turn_around()

    var turn_weight := 1.0 - exp(-turn_smoothing * delta)
    rotation.y = lerp_angle(rotation.y, target_yaw, turn_weight)

    var forward_amount := Input.get_action_strength("move_forward")
    var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
    var forward := -global_transform.basis.z
    forward.y = 0.0
    forward = forward.normalized()

    velocity.x = forward.x * speed * forward_amount
    velocity.z = forward.z * speed * forward_amount
    velocity.y = 0.0
    move_and_slide()

func request_turn_around() -> void:
    target_yaw = wrapf(target_yaw + PI, -PI, PI)

func _unhandled_input(event: InputEvent) -> void:
    if not enabled or world == null:
        return
    if event.is_action_pressed("interact"):
        world.try_interact()
    elif event.is_action_pressed("inventory"):
        world.toggle_inventory()
    elif event.is_action_pressed("use_bandage"):
        world.use_bandage()
