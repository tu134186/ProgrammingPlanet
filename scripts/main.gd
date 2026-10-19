extends Node3D
## V0.2.0 mobile-first exploration prototype. No arbitrary code execution.
var steps: Array[String] = []
var robot: Node3D
var player: CharacterBody3D
var status: Label
var tasks: Label
var lesson_index := 0
var challenges := ["向前移动 3 步", "向右转并前进 2 步", "重复前进 4 步"]

func _ready() -> void:
    _create_world()
    _create_interface()
    _refresh()

func _create_world() -> void:
    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.44, 0.75, 0.96)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color.WHITE
    env.ambient_light_energy = 0.8
    environment.environment = env
    add_child(environment)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, 30, 0)
    add_child(sun)
    _box(Vector3(0, -0.35, 0), Vector3(22, 0.6, 22), Color(0.30, 0.69, 0.43))
    for i in range(8):
        _box(Vector3(-8 + i * 2.2, 0.2, -5), Vector3(0.9, 1.1, 0.9), Color(0.87, 0.66, 0.36))
    player = CharacterBody3D.new()
    player.position = Vector3(0, 0.65, 0)
    add_child(player)
    _box(Vector3(0, 0.0, 0), Vector3(0.7, 1.2, 0.7), Color(0.27, 0.43, 0.9), player)
    robot = Node3D.new()
    robot.position = Vector3(2, 0.65, 0)
    add_child(robot)
    _box(Vector3.ZERO, Vector3(0.75, 0.85, 0.75), Color(1.0, 0.73, 0.23), robot)
    var camera := Camera3D.new()
    camera.position = Vector3(8, 11, 15)
    camera.look_at(Vector3.ZERO)
    camera.current = true
    add_child(camera)

func _box(pos: Vector3, size: Vector3, color: Color, parent: Node = self) -> void:
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    mesh.material_override = material
    mesh.position = pos
    parent.add_child(mesh)

func _create_interface() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var root := MarginContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("margin_left", 22)
    root.add_theme_constant_override("margin_top", 52)
    root.add_theme_constant_override("margin_right", 22)
    root.add_theme_constant_override("margin_bottom", 22)
    layer.add_child(root)
    var column := VBoxContainer.new()
    root.add_child(column)
    var title := Label.new()
    title.text = "编程星球 · V0.2.0"
    title.add_theme_font_size_override("font_size", 28)
    column.add_child(title)
    tasks = Label.new()
    column.add_child(tasks)
    status = Label.new()
    column.add_child(status)
    var space := Control.new()
    space.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_child(space)
    var bar := HBoxContainer.new()
    column.add_child(bar)
    for label in ["前进", "右转", "重复", "执行", "清空"]:
        var b := Button.new()
        b.text = label
        b.custom_minimum_size = Vector2(0, 64)
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.pressed.connect(_pressed.bind(label))
        bar.add_child(b)

func _pressed(action: String) -> void:
    match action:
        "前进", "右转": steps.append(action)
        "重复":
            if not steps.is_empty(): steps.append(steps.back())
        "清空": steps.clear()
        "执行":
            var facing := 0
            var start := robot.position
            for step in steps:
                if step == "右转": facing = (facing + 1) % 4
                elif step == "前进":
                    var dirs := [Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0)]
                    robot.position += dirs[facing]
            if robot.position.distance_to(start) > 0.1:
                lesson_index = mini(lesson_index + 1, challenges.size() - 1)
            steps.clear()
    _refresh()

func _refresh() -> void:
    tasks.text = "自由挑战：%s" % challenges[lesson_index]
    status.text = "积木指令：%s" % (" → ".join(steps) if not steps.is_empty() else "点击下方积木开始")
