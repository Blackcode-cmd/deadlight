extends Node

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const FOLLOW_CAMERA_SCRIPT = preload("res://scripts/follow_camera.gd")

const STAT_NAMES := [
    "Strength", "Endurance", "Agility", "Perception", "Intelligence",
    "Charisma", "Craftsmanship", "Science", "Survival", "Luck"
]

var rng := RandomNumberGenerator.new()
var selected_stats: Array[String] = []
var primary_stat := ""
var secondary_stats: Array[String] = []
var shirt_color := Color(0.15, 0.35, 0.8)

var world_root: Node3D
var player: CharacterBody3D
var camera: Camera3D
var interactables: Array[Dictionary] = []

var tutorial_started := false
var run_elapsed := 0.0
var house_entered := false
var house_one_completed := false
var front_door_open := false
var side_door_open := false
var hazard_triggered := false
var bleeding := false
var health := 100.0
var character_xp := 0
var shelter_xp := 0
var meaningful_loot_found := false
var bandage_tutorial_completed := false

var inventory := {
    "Wooden Plank": 0,
    "Scrap": 0,
    "Bandage": 0,
    "Hidden Cache": 0
}
var discovered := {}

var ui: CanvasLayer
var objective_label: Label
var status_label: Label
var prompt_label: Label
var timer_label: Label
var xp_label: Label
var health_label: Label
var inventory_panel: PanelContainer
var inventory_label: Label
var message_panel: PanelContainer
var message_label: Label
var message_timer := 0.0

func _ready() -> void:
    rng.randomize()
    setup_input_map()
    show_main_menu()

func setup_input_map() -> void:
    var bindings := {
        "move_forward": [KEY_W, KEY_UP],
        "turn_around": [KEY_S, KEY_DOWN],
        "turn_left": [KEY_A, KEY_LEFT],
        "turn_right": [KEY_D, KEY_RIGHT],
        "sprint": [KEY_SHIFT],
        "interact": [KEY_E],
        "inventory": [KEY_I],
        "use_bandage": [KEY_B]
    }
    for action_name in bindings.keys():
        if not InputMap.has_action(action_name):
            InputMap.add_action(action_name)
        for keycode in bindings[action_name]:
            var already_bound := false
            for existing in InputMap.action_get_events(action_name):
                if existing is InputEventKey and existing.physical_keycode == keycode:
                    already_bound = true
                    break
            if not already_bound:
                var ev := InputEventKey.new()
                ev.physical_keycode = keycode
                InputMap.action_add_event(action_name, ev)

func _process(delta: float) -> void:
    if tutorial_started:
        run_elapsed += delta
        if timer_label:
            timer_label.text = "RUN TIME  %s" % format_time(run_elapsed)
        if bleeding:
            health = max(65.0, health - delta * 0.6)
            update_health_ui()
        check_nail_hazard()
        check_house_one_completion()
        update_interaction_prompt()

    if message_timer > 0.0:
        message_timer -= delta
        if message_timer <= 0.0 and message_panel:
            message_panel.visible = false

func show_main_menu() -> void:
    clear_children()
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(root)

    var bg := ColorRect.new()
    bg.color = Color(0.035, 0.045, 0.055)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_child(bg)

    var center := VBoxContainer.new()
    center.set_anchors_preset(Control.PRESET_CENTER)
    center.position = Vector2(-170, -190)
    center.size = Vector2(340, 380)
    center.add_theme_constant_override("separation", 14)
    root.add_child(center)

    var title := Label.new()
    title.text = "PROJECT DEADLIGHT"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    center.add_child(title)

    var sub := Label.new()
    sub.text = "HOUSE 1 GRAYBOX"
    sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sub.add_theme_font_size_override("font_size", 16)
    center.add_child(sub)

    var start_btn := Button.new()
    start_btn.text = "Start Game"
    start_btn.custom_minimum_size = Vector2(0, 48)
    start_btn.pressed.connect(show_character_setup)
    center.add_child(start_btn)

    var load_btn := Button.new()
    load_btn.text = "Load Save (not in V1)"
    load_btn.disabled = true
    center.add_child(load_btn)

    var settings_btn := Button.new()
    settings_btn.text = "Settings (placeholder)"
    settings_btn.pressed.connect(func(): show_message("Settings will be added after the graybox loop is proven."))
    center.add_child(settings_btn)

    var quit_btn := Button.new()
    quit_btn.text = "Quit"
    quit_btn.pressed.connect(func(): get_tree().quit())
    center.add_child(quit_btn)

    var credits := Label.new()
    credits.text = "Trio Mind's Digital  •  Code3Builder"
    credits.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    credits.position = Vector2(18, -38)
    credits.add_theme_font_size_override("font_size", 12)
    root.add_child(credits)

    var version := Label.new()
    version.text = "Graybox V1.2  •  2026-09-22"
    version.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    version.position = Vector2(-220, -38)
    version.add_theme_font_size_override("font_size", 12)
    root.add_child(version)

func show_character_setup() -> void:
    clear_children()
    selected_stats.clear()
    primary_stat = ""
    secondary_stats.clear()

    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(root)

    var title := Label.new()
    title.text = "Create Your First Character"
    title.position = Vector2(40, 28)
    title.add_theme_font_size_override("font_size", 28)
    root.add_child(title)

    var help := Label.new()
    help.text = "Choose 1 Primary stat first, then 3 Secondary stats. The remaining stats become unavailable for this character."
    help.position = Vector2(42, 75)
    help.size = Vector2(1160, 50)
    help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    root.add_child(help)

    var stat_box := GridContainer.new()
    stat_box.columns = 2
    stat_box.position = Vector2(42, 135)
    stat_box.size = Vector2(620, 450)
    stat_box.add_theme_constant_override("h_separation", 10)
    stat_box.add_theme_constant_override("v_separation", 10)
    root.add_child(stat_box)

    var selection_label := Label.new()
    selection_label.name = "SelectionLabel"
    selection_label.text = "Primary: —\nSecondary: —"
    selection_label.position = Vector2(710, 145)
    selection_label.size = Vector2(480, 80)
    root.add_child(selection_label)

    for stat_name in STAT_NAMES:
        var b := Button.new()
        b.text = stat_name
        b.custom_minimum_size = Vector2(260, 48)
        b.name = "Stat_%s" % stat_name
        b.pressed.connect(choose_stat.bind(stat_name, root))
        stat_box.add_child(b)

    var color_title := Label.new()
    color_title.text = "Basic shirt color"
    color_title.position = Vector2(710, 260)
    root.add_child(color_title)

    var colors := {
        "Blue": Color(0.15, 0.35, 0.8),
        "Red": Color(0.75, 0.15, 0.15),
        "Green": Color(0.12, 0.55, 0.25),
        "Orange": Color(0.9, 0.4, 0.08)
    }
    var color_box := HBoxContainer.new()
    color_box.position = Vector2(710, 295)
    root.add_child(color_box)
    for color_name in colors.keys():
        var cb := Button.new()
        cb.text = color_name
        cb.pressed.connect(set_shirt_color.bind(colors[color_name]))
        color_box.add_child(cb)

    var confirm := Button.new()
    confirm.name = "ConfirmButton"
    confirm.text = "Confirm Character"
    confirm.disabled = true
    confirm.position = Vector2(710, 385)
    confirm.size = Vector2(250, 55)
    confirm.pressed.connect(build_tutorial_world)
    root.add_child(confirm)

    var back := Button.new()
    back.text = "Back"
    back.position = Vector2(710, 455)
    back.size = Vector2(250, 45)
    back.pressed.connect(show_main_menu)
    root.add_child(back)

func choose_stat(stat_name: String, root: Control) -> void:
    if stat_name in selected_stats or selected_stats.size() >= 4:
        return
    selected_stats.append(stat_name)
    if selected_stats.size() == 1:
        primary_stat = stat_name
    else:
        secondary_stats.append(stat_name)

    var label := root.get_node("SelectionLabel") as Label
    label.text = "Primary: %s\nSecondary: %s" % [primary_stat, ", ".join(secondary_stats)]

    if selected_stats.size() == 4:
        for stat_name_iter in STAT_NAMES:
            var button := root.find_child("Stat_%s" % stat_name_iter, true, false) as Button
            if button and stat_name_iter not in selected_stats:
                button.disabled = true
        var confirm := root.get_node("ConfirmButton") as Button
        confirm.disabled = false

func set_shirt_color(color: Color) -> void:
    shirt_color = color

func build_tutorial_world() -> void:
    clear_children()
    tutorial_started = true
    run_elapsed = 0.0
    bleeding = false
    health = 100.0
    character_xp = 0
    shelter_xp = 0
    hazard_triggered = false
    house_entered = false
    house_one_completed = false
    front_door_open = false
    side_door_open = false
    meaningful_loot_found = false
    bandage_tutorial_completed = false
    interactables.clear()
    inventory = {"Wooden Plank": 0, "Scrap": 0, "Bandage": 0, "Hidden Cache": 0}
    discovered.clear()

    world_root = Node3D.new()
    world_root.name = "World"
    add_child(world_root)

    make_environment()
    build_ground_and_street()
    build_shelter_shell()
    build_house_one()
    build_player()
    build_hud()

    objective_label.text = "House 1: Cross the street and inspect the abandoned house. There is always at least one way in without a skill check."
    show_message("W / Up: Walk forward  •  A/D or Left/Right: Turn  •  S / Down: Turn around  •  Shift: Sprint  •  E: Interact", 9.0)

func make_environment() -> void:
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(0.025, 0.035, 0.06)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(0.28, 0.32, 0.45)
    e.ambient_light_energy = 0.55
    e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.environment = e
    world_root.add_child(env)

    var moon := DirectionalLight3D.new()
    moon.rotation_degrees = Vector3(-58, -25, 0)
    moon.light_color = Color(0.62, 0.72, 1.0)
    moon.light_energy = 1.0
    moon.shadow_enabled = true
    world_root.add_child(moon)

func build_ground_and_street() -> void:
    add_box(Vector3(0, -0.3, 0), Vector3(58, 0.5, 48), Color(0.11, 0.16, 0.11), true)
    add_box(Vector3(0, 0.0, 0), Vector3(8, 0.08, 48), Color(0.11, 0.11, 0.12), false)
    add_box(Vector3(-5.0, 0.02, 0), Vector3(1.6, 0.08, 48), Color(0.3, 0.3, 0.3), false)
    add_box(Vector3(5.0, 0.02, 0), Vector3(1.6, 0.08, 48), Color(0.3, 0.3, 0.3), false)
    add_box(Vector3(1.5, 0.65, -9), Vector3(2.0, 1.1, 4.2), Color(0.22, 0.18, 0.15), true)

func build_shelter_shell() -> void:
    add_box(Vector3(-14, 1.5, 9), Vector3(10, 3, 9), Color(0.22, 0.23, 0.25), true)
    add_box(Vector3(-14, 3.2, 9), Vector3(11, 0.5, 10), Color(0.12, 0.12, 0.14), false)
    for z in [-1.0, 3.0, 7.0, 11.0, 15.0, 19.0]:
        add_box(Vector3(-8.2, 0.7, z), Vector3(0.25, 1.4, 3.2), Color(0.36, 0.28, 0.19), true)

func build_house_one() -> void:
    var wall_color := Color(0.42, 0.42, 0.39)
    var floor_color := Color(0.26, 0.23, 0.20)
    add_box(Vector3(16, 0.06, 5), Vector3(12, 0.12, 16), floor_color, false)

    add_box(Vector3(10.1, 1.5, 1.0), Vector3(0.25, 3, 8.0), wall_color, true)
    add_box(Vector3(10.1, 1.5, 10.5), Vector3(0.25, 3, 5.0), wall_color, true)
    add_box(Vector3(21.9, 1.5, 5), Vector3(0.25, 3, 16), wall_color, true)
    add_box(Vector3(16, 1.5, -2.9), Vector3(12, 3, 0.25), wall_color, true)
    add_box(Vector3(13.0, 1.5, 12.9), Vector3(6.0, 3, 0.25), wall_color, true)
    add_box(Vector3(19.5, 1.5, 12.9), Vector3(5.0, 3, 0.25), wall_color, true)

    var inner_wall := Color(0.38, 0.37, 0.34)
    add_box(Vector3(16, 1.4, -0.2), Vector3(0.2, 2.8, 5.2), inner_wall, true)
    add_box(Vector3(16, 1.4, 5.6), Vector3(0.2, 2.8, 2.6), inner_wall, true)
    add_box(Vector3(11.5, 1.4, 7.0), Vector3(2.6, 2.8, 0.2), inner_wall, true)
    add_box(Vector3(15.0, 1.4, 7.0), Vector3(2.0, 2.8, 0.2), inner_wall, true)
    add_box(Vector3(17.1, 1.4, 7.0), Vector3(2.0, 2.8, 0.2), inner_wall, true)
    add_box(Vector3(20.9, 1.4, 7.0), Vector3(1.8, 2.8, 0.2), inner_wall, true)

    add_box(Vector3(7.0, 0.03, 5.6), Vector3(5.7, 0.08, 1.7), Color(0.34, 0.34, 0.32), false)
    add_box(Vector3(9.0, 0.18, 5.6), Vector3(2.0, 0.35, 2.6), Color(0.31, 0.29, 0.27), true)
    add_box(Vector3(9.0, 3.05, 5.6), Vector3(3.2, 0.2, 4.2), Color(0.17, 0.16, 0.15), false)
    add_box(Vector3(8.1, 1.5, 4.2), Vector3(0.15, 3.0, 0.15), Color(0.25, 0.23, 0.20), true)
    add_box(Vector3(8.1, 1.5, 7.0), Vector3(0.15, 3.0, 0.15), Color(0.25, 0.23, 0.20), true)

    var door := add_box(Vector3(10.0, 1.25, 5.6), Vector3(0.35, 2.5, 1.7), Color(0.30, 0.20, 0.12), true)
    door.name = "FrontDoorBlocker"
    var side_door := add_box(Vector3(17.0, 1.25, 12.85), Vector3(1.7, 2.5, 0.35), Color(0.30, 0.20, 0.12), true)
    side_door.name = "SideDoorBlocker"
    add_box(Vector3(10.0, 1.65, 9.0), Vector3(0.12, 1.3, 1.8), Color(0.12, 0.23, 0.32), false)

    add_box(Vector3(13.0, 0.5, 2.0), Vector3(2.7, 1.0, 1.2), Color(0.22, 0.18, 0.16), true)
    add_box(Vector3(11.5, 0.7, 2.0), Vector3(0.45, 1.4, 1.7), Color(0.06, 0.07, 0.08), true)
    add_box(Vector3(13.7, 0.45, 3.8), Vector3(1.0, 0.9, 0.7), Color(0.30, 0.25, 0.19), true)

    add_box(Vector3(18.5, 0.55, 1.0), Vector3(4.3, 1.1, 1.0), Color(0.32, 0.27, 0.20), true)
    add_box(Vector3(19.9, 0.9, 9.6), Vector3(2.3, 1.8, 3.2), Color(0.24, 0.22, 0.20), true)
    add_box(Vector3(12.2, 0.8, 9.6), Vector3(1.5, 1.6, 1.5), Color(0.35, 0.34, 0.32), true)

    add_interactable("front_door", Vector3(8.9, 0.7, 5.6), "[Strength • Moderate] Bust front door — E")
    add_interactable("agility_window", Vector3(9.0, 0.7, 9.0), "[Agility • Moderate] Climb through window — E")
    add_interactable("side_door", Vector3(17.0, 0.7, 14.0), "Unlocked side door — E (No Check)")

    add_interactable("tv", Vector3(11.5, 0.7, 2.0), "Old television — E to inspect")
    add_interactable("family_photo", Vector3(13.6, 0.7, 3.8), "Dusty family photo — E to inspect")
    add_interactable("empty_drawer", Vector3(18.0, 0.6, 1.1), "Kitchen drawer — E to search")
    add_interactable("empty_fridge", Vector3(20.2, 0.7, 2.0), "Old refrigerator — E to search")

    add_interactable("newspaper", Vector3(14.0, 0.2, 2.6), "Old newspaper — E to read")
    add_interactable("planks", Vector3(10.8, 0.4, 10.7), "Loose wooden planks — E to salvage")
    add_interactable("scrap", Vector3(18.8, 0.6, 1.0), "Kitchen junk pile — E to scavenge")
    add_interactable("bathroom_cabinet", Vector3(12.2, 0.7, 9.6), "Bathroom cabinet — E to search")
    add_interactable("hidden_stash", Vector3(14.7, 0.15, 10.2), "Something seems unusual here — E to inspect", true)

func build_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.collision_layer = 2
    player.collision_mask = 1
    player.set_script(PLAYER_SCRIPT)
    world_root.add_child(player)
    player.global_position = Vector3(-9.8, 0.75, 3.7)
    player.world = self
    player.enabled = true

    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.42
    capsule.height = 1.5
    collider.shape = capsule
    player.add_child(collider)

    var body := MeshInstance3D.new()
    var capsule_mesh := CapsuleMesh.new()
    capsule_mesh.radius = 0.42
    capsule_mesh.height = 1.5
    body.mesh = capsule_mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = shirt_color
    body.material_override = mat
    player.add_child(body)

    camera = Camera3D.new()
    camera.name = "FollowCamera"
    camera.set_script(FOLLOW_CAMERA_SCRIPT)
    world_root.add_child(camera)
    camera.target = player
    camera.current = true
    camera.snap_to_target()

    var facing_marker := MeshInstance3D.new()
    var marker_mesh := BoxMesh.new()
    marker_mesh.size = Vector3(0.22, 0.22, 0.42)
    facing_marker.mesh = marker_mesh
    facing_marker.position = Vector3(0, 0.15, -0.48)
    var marker_mat := StandardMaterial3D.new()
    marker_mat.albedo_color = Color(0.92, 0.92, 0.95)
    facing_marker.material_override = marker_mat
    player.add_child(facing_marker)

func build_hud() -> void:
    ui = CanvasLayer.new()
    add_child(ui)

    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.add_child(root)

    var top := PanelContainer.new()
    top.position = Vector2(18, 16)
    top.size = Vector2(520, 118)
    root.add_child(top)
    var top_box := VBoxContainer.new()
    top.add_child(top_box)

    objective_label = Label.new()
    objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    top_box.add_child(objective_label)
    status_label = Label.new()
    status_label.text = "Primary %s  |  Secondary %s" % [primary_stat, ", ".join(secondary_stats)]
    top_box.add_child(status_label)

    timer_label = Label.new()
    timer_label.text = "RUN TIME  00:00:00"
    timer_label.position = Vector2(1060, 18)
    root.add_child(timer_label)

    xp_label = Label.new()
    xp_label.position = Vector2(1035, 46)
    root.add_child(xp_label)

    health_label = Label.new()
    health_label.position = Vector2(1035, 74)
    root.add_child(health_label)
    update_xp_ui()
    update_health_ui()

    prompt_label = Label.new()
    prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt_label.position = Vector2(300, 642)
    prompt_label.size = Vector2(680, 44)
    prompt_label.add_theme_font_size_override("font_size", 18)
    root.add_child(prompt_label)

    inventory_panel = PanelContainer.new()
    inventory_panel.position = Vector2(870, 420)
    inventory_panel.size = Vector2(370, 205)
    inventory_panel.visible = false
    root.add_child(inventory_panel)
    inventory_label = Label.new()
    inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    inventory_panel.add_child(inventory_label)
    refresh_inventory()

    message_panel = PanelContainer.new()
    message_panel.position = Vector2(300, 515)
    message_panel.size = Vector2(680, 105)
    message_panel.visible = false
    root.add_child(message_panel)
    message_label = Label.new()
    message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message_panel.add_child(message_label)

func add_box(pos: Vector3, size: Vector3, color: Color, collision: bool) -> Node3D:
    var root := Node3D.new()
    root.position = pos
    world_root.add_child(root)

    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.9
    mesh_instance.material_override = material
    root.add_child(mesh_instance)

    if collision:
        var static_body := StaticBody3D.new()
        static_body.collision_layer = 1
        static_body.collision_mask = 2
        var shape_node := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        shape_node.shape = shape
        static_body.add_child(shape_node)
        root.add_child(static_body)
    return root

func add_interactable(id: String, pos: Vector3, prompt: String, hidden := false) -> void:
    interactables.append({"id": id, "position": pos, "prompt": prompt, "used": false, "hidden": hidden})

func try_interact() -> void:
    if player == null:
        return
    var best_index := -1
    var best_distance := 2.2
    for i in range(interactables.size()):
        var item := interactables[i]
        if item["used"]:
            continue
        if item["hidden"] and not can_reveal_hidden(item["id"]):
            continue
        var d: float = player.global_position.distance_to(item["position"])
        if d < best_distance:
            best_distance = d
            best_index = i
    if best_index >= 0:
        resolve_interaction(best_index)

func resolve_interaction(index: int) -> void:
    var id: String = interactables[index]["id"]
    match id:
        "front_door":
            attempt_front_door(index)
        "agility_window":
            attempt_window_entry(index)
        "side_door":
            open_side_door(index)
        "tv":
            show_message("I remember being glued to these for hours.")
            interactables[index]["used"] = true
        "family_photo":
            show_message("A family used to live here. Whoever left, they didn't take much with them.")
            interactables[index]["used"] = true
        "empty_drawer":
            show_message("Nothing useful. Most things you search won't be worth carrying.")
            interactables[index]["used"] = true
        "empty_fridge":
            show_message("Spoiled food and an awful smell. Nothing worth taking.")
            interactables[index]["used"] = true
        "newspaper":
            if not discovered.has("newspaper"):
                discovered["newspaper"] = true
                grant_xp(5, "Lore discovered")
                show_message("The paper describes early emergency curfews after the first Deadlight incidents. Lore discovered: +5 XP")
            else:
                show_message("You've already read this newspaper.")
            interactables[index]["used"] = true
        "planks":
            inventory["Wooden Plank"] += 2
            meaningful_loot_found = true
            refresh_inventory()
            show_message("Salvaged 2 Wooden Planks. Shelter-upgrade resources can be more valuable than cash.")
            interactables[index]["used"] = true
        "scrap":
            inventory["Scrap"] += 1
            meaningful_loot_found = true
            refresh_inventory()
            show_message("Found 1 usable Scrap. Most of the pile is worthless.")
            interactables[index]["used"] = true
        "bathroom_cabinet":
            inventory["Bandage"] += 1
            refresh_inventory()
            show_message("Found 1 Bandage. Keep it — the house isn't completely safe.")
            interactables[index]["used"] = true
        "hidden_stash":
            inventory["Hidden Cache"] += 1
            meaningful_loot_found = true
            refresh_inventory()
            grant_xp(5, "Hidden stash discovered")
            show_message("Hidden cache discovered. Careful exploration can pay off: +5 XP")
            interactables[index]["used"] = true

func attempt_front_door(index: int) -> void:
    if front_door_open:
        return
    if not has_stat("Strength"):
        show_message("The front door is locked. Without Strength, forcing it isn't one of this character's available solutions. Look for another route.")
        return

    var role := "Primary" if primary_stat == "Strength" else "Secondary"
    var chance := skill_chance("Strength", "Moderate")
    if rng.randf() <= chance:
        front_door_open = true
        remove_named_blocker("FrontDoorBlocker")
        grant_xp(10, "Moderate Strength check")
        show_message("[Strength • Moderate • %s] Success. You smash the abandoned door inward. +10 XP" % role)
        interactables[index]["used"] = true
        on_house_entered("Strength")
    else:
        health = max(85.0, health - 4.0)
        update_health_ui()
        show_message("[Strength • Moderate • %s] Failed. Your shoulder aches. You may retry, but repeated force can injure characters outside the tutorial." % role)

func attempt_window_entry(index: int) -> void:
    if not has_stat("Agility"):
        show_message("Without Agility, this character doesn't see a safe way through the window. Try another entrance.")
        return
    var role := "Primary" if primary_stat == "Agility" else "Secondary"
    var chance := skill_chance("Agility", "Moderate")
    if rng.randf() <= chance:
        player.global_position = Vector3(11.3, 0.75, 9.0)
        grant_xp(10, "Moderate Agility check")
        show_message("[Agility • Moderate • %s] You slip through the window cleanly. +10 XP" % role)
        interactables[index]["used"] = true
        on_house_entered("Agility")
    else:
        show_message("[Agility • Moderate • %s] You lose your footing and back off before getting hurt. Retry or use another entrance." % role)

func open_side_door(index: int) -> void:
    if not side_door_open:
        side_door_open = true
        remove_named_blocker("SideDoorBlocker")
        show_message("The side door was never locked. No check, no XP — ordinary interactions are not progression.")
        interactables[index]["used"] = true
        on_house_entered("No Check")

func on_house_entered(method: String) -> void:
    if house_entered:
        return
    house_entered = true
    objective_label.text = "House 1: Search the living room. Most scenery is just scenery; useful loot should feel uncommon."
    if method == "No Check":
        show_message("You entered without using a skill. Specialized builds create options, but the tutorial never requires a specific stat.", 6.0)

func remove_named_blocker(node_name: String) -> void:
    var blocker := world_root.find_child(node_name, true, false)
    if blocker:
        blocker.queue_free()

func has_stat(stat_name: String) -> bool:
    return stat_name == primary_stat or stat_name in secondary_stats

func skill_chance(stat_name: String, difficulty: String) -> float:
    var primary := stat_name == primary_stat
    var table_primary := {"Simple": 1.0, "Moderate": 0.90, "Difficult": 0.70, "Expert": 0.50, "Exceptional": 0.25}
    var table_secondary := {"Simple": 0.90, "Moderate": 0.70, "Difficult": 0.45, "Expert": 0.0, "Exceptional": 0.0}
    return table_primary[difficulty] if primary else table_secondary[difficulty]

func can_reveal_hidden(id: String) -> bool:
    if id != "hidden_stash":
        return true
    if not has_stat("Perception"):
        return false
    var dist := player.global_position.distance_to(Vector3(14.7, 0.15, 10.2))
    if dist > 2.5:
        return false
    if discovered.has("hidden_stash_roll"):
        return bool(discovered["hidden_stash_roll"])

    var found := rng.randf() <= (0.92 if primary_stat == "Perception" else 0.65)
    discovered["hidden_stash_roll"] = found
    if found:
        show_message("Your Perception catches a floorboard that doesn't sit quite right.")
    return found

func update_interaction_prompt() -> void:
    if player == null or prompt_label == null:
        return
    var best_prompt := ""
    var best_distance := 2.2
    for item in interactables:
        if item["used"]:
            continue
        if item["hidden"] and not can_reveal_hidden(item["id"]):
            continue
        var d: float = player.global_position.distance_to(item["position"])
        if d < best_distance:
            best_distance = d
            best_prompt = item["prompt"]
    prompt_label.text = best_prompt

func check_nail_hazard() -> void:
    if hazard_triggered or player == null or not house_entered:
        return
    var hazard_pos := Vector3(14.0, 0.0, 5.2)
    if player.global_position.distance_to(hazard_pos) < 0.8:
        hazard_triggered = true
        bleeding = true
        health = 94.0
        update_health_ui()
        objective_label.text = "House 1: You are bleeding. Search the bathroom cabinet for a Bandage, then press B to use it."
        show_message("You step on a loose plank with a rusty nail. BLEEDING. Tutorial injuries cannot kill you — real runs will not protect you.", 7.0)

func use_bandage() -> void:
    if not bleeding:
        show_message("You are not bleeding.")
        return
    if inventory["Bandage"] <= 0:
        show_message("No Bandage. Search the bathroom cabinet.")
        return
    inventory["Bandage"] -= 1
    bleeding = false
    bandage_tutorial_completed = true
    health = min(100.0, health + 8.0)
    refresh_inventory()
    update_health_ui()
    objective_label.text = "House 1: Bleeding stopped. Scavenge anything else you want, then leave the house."
    show_message("Bandage applied. Consumables are carried into runs and are lost with the character if they die.", 6.0)

func check_house_one_completion() -> void:
    if house_one_completed or not house_entered or not bandage_tutorial_completed or player == null:
        return
    var outside := player.global_position.x < 9.45 or player.global_position.z > 13.35
    if not outside:
        return
    house_one_completed = true
    var loot_line := "You found useful resources." if meaningful_loot_found else "You left without much useful loot — that is normal in Deadlight."
    objective_label.text = "House 1 complete. Next: House 2 will introduce deeper skill checks and tools."
    show_message("HOUSE 1 COMPLETE\n%s\nYou learned entry choices, scavenging, hidden finds, minor injury, and consumable use." % loot_line, 9.0)

func grant_xp(amount: int, _reason: String) -> void:
    character_xp += amount
    shelter_xp += amount
    update_xp_ui()

func update_xp_ui() -> void:
    if xp_label:
        xp_label.text = "Character XP %d  |  Shelter XP %d" % [character_xp, shelter_xp]

func update_health_ui() -> void:
    if health_label:
        var suffix := "  •  BLEEDING" if bleeding else ""
        health_label.text = "Health %d%%%s" % [int(health), suffix]

func toggle_inventory() -> void:
    if inventory_panel:
        inventory_panel.visible = not inventory_panel.visible
        refresh_inventory()

func refresh_inventory() -> void:
    if inventory_label == null:
        return
    var lines := ["BACKPACK — HOUSE 1"]
    for key in inventory.keys():
        lines.append("%s: %d" % [key, inventory[key]])
    lines.append("")
    lines.append("I = Close Backpack")
    lines.append("B = Use Bandage")
    inventory_label.text = "\n".join(lines)

func show_message(text: String, seconds := 4.5) -> void:
    if message_panel == null:
        print(text)
        return
    message_label.text = text
    message_panel.visible = true
    message_timer = seconds

func format_time(total_seconds: float) -> String:
    var t := int(total_seconds)
    var h := int(t / 3600)
    var m := int((t % 3600) / 60)
    var s := t % 60
    return "%02d:%02d:%02d" % [h, m, s]

func clear_children() -> void:
    tutorial_started = false
    for child in get_children():
        child.queue_free()
