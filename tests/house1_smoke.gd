extends SceneTree

func _init() -> void:
    call_deferred("run")

func fail_test(message: String) -> void:
    printerr("HOUSE1_SMOKE_FAIL: %s" % message)
    quit(1)

func find_interactable_index(main: Node, id: String) -> int:
    for i in range(main.interactables.size()):
        if main.interactables[i]["id"] == id:
            return i
    return -1

func run() -> void:
    var scene := load("res://main.tscn") as PackedScene
    if scene == null:
        fail_test("main.tscn failed to load")
        return

    var main := scene.instantiate()
    root.add_child(main)
    await process_frame

    main.primary_stat = "Strength"
    main.secondary_stats.clear()
    main.secondary_stats.append("Agility")
    main.secondary_stats.append("Perception")
    main.secondary_stats.append("Survival")
    main.selected_stats.clear()
    main.selected_stats.append("Strength")
    main.selected_stats.append("Agility")
    main.selected_stats.append("Perception")
    main.selected_stats.append("Survival")
    main.build_tutorial_world()
    await process_frame
    await process_frame

    if main.player == null:
        fail_test("player not created")
        return
    if main.interactables.size() < 10:
        fail_test("expected House 1 interactables")
        return

    var side_index := find_interactable_index(main, "side_door")
    if side_index < 0:
        fail_test("side door missing")
        return
    main.open_side_door(side_index)
    await process_frame
    if not main.house_entered:
        fail_test("side-door entry did not mark house entered")
        return

    var cabinet_index := find_interactable_index(main, "bathroom_cabinet")
    if cabinet_index < 0:
        fail_test("bathroom cabinet missing")
        return
    main.resolve_interaction(cabinet_index)
    if main.inventory["Bandage"] != 1:
        fail_test("bandage was not added")
        return

    main.player.global_position = Vector3(14.0, 0.75, 5.2)
    main.check_nail_hazard()
    if not main.bleeding:
        fail_test("nail hazard did not start bleeding")
        return

    main.use_bandage()
    if main.bleeding or not main.bandage_tutorial_completed:
        fail_test("bandage did not complete treatment")
        return

    main.player.global_position = Vector3(8.8, 0.75, 5.6)
    main.check_house_one_completion()
    if not main.house_one_completed:
        fail_test("leaving after treatment did not complete House 1")
        return

    print("HOUSE1_SMOKE_PASS")
    quit(0)
