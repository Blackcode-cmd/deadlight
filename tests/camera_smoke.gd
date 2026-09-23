extends SceneTree

func fail_test(message: String) -> void:
    printerr("CAMERA_SMOKE_FAIL: %s" % message)
    quit(1)

func _init() -> void:
    call_deferred("run")

func run() -> void:
    var scene: PackedScene = load("res://main.tscn") as PackedScene
    if scene == null:
        fail_test("main scene failed to load")
        return

    var main: Node = scene.instantiate()
    root.add_child(main)
    await process_frame

    main.set("primary_stat", "Strength")
    main.set("secondary_stats", ["Agility", "Perception", "Survival"])
    main.set("selected_stats", ["Strength", "Agility", "Perception", "Survival"])
    main.call("build_tutorial_world")
    await process_frame
    await process_frame

    var player: CharacterBody3D = main.get("player") as CharacterBody3D
    var camera: Camera3D = main.get("camera") as Camera3D
    if player == null or camera == null:
        fail_test("player or follow camera missing")
        return

    var start_yaw: float = float(player.get("target_yaw"))
    player.call("request_turn_around")
    var end_yaw: float = float(player.get("target_yaw"))
    var yaw_delta: float = abs(wrapf(end_yaw - start_yaw, -PI, PI))
    if abs(yaw_delta - PI) > 0.01:
        fail_test("turn-around did not request 180 degrees")
        return

    if camera.get("target") != player:
        fail_test("camera target is not player")
        return

    var expected_behind: Vector3 = player.global_transform.basis.z.normalized()
    var camera_planar: Vector3 = camera.global_position - player.global_position
    camera_planar.y = 0.0
    if camera_planar.length() < 0.1:
        fail_test("camera is not offset behind player")
        return
    camera_planar = camera_planar.normalized()
    if camera_planar.dot(expected_behind) < 0.95:
        fail_test("camera is not positioned behind facing direction")
        return

    print("CAMERA_SMOKE_PASS")
    quit(0)
