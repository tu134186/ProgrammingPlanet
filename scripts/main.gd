extends Node3D
## V0.4.0 - third-person exploration and programming modes.
const HOME := Vector3(-4, 0.7, 2)
const UNIT := 2.0
var robot: Node3D
var steps: Array[String] = []
var level := 0
var busy := false
var queue_label: Label
var mission_label: Label
var feedback: Label
var execute_button: Button
var camera: Camera3D
var programming_panel: PanelContainer
var mode_button: Button
var hint_label: Label
var exploration := true
var camera_yaw := 0.0
var camera_pitch := 0.42
var camera_distance := 8.5
var move_axis := Vector2.ZERO
var move_touch := -1
var look_touch := -1
var move_origin := Vector2.ZERO
var viewport_width := 1.0
var goals := [Vector3(-4, 0.7, -4), Vector3(0, 0.7, -4), Vector3(4, 0.7, -4)]
var lessons := ["添加三个前进积木，抵达第一颗星星", "组合前进和转弯，探索第二颗星星", "自由挑战：设计路线，寻找第三颗星星"]

func _ready() -> void:
    _world()
    _ui()
    _refresh()
    _set_mode(true)

func _box(parent: Node, pos: Vector3, size: Vector3, color: Color) -> void:
    var mesh := MeshInstance3D.new()
    var shape := BoxMesh.new()
    shape.size = size
    mesh.mesh = shape
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mesh.material_override = mat
    mesh.position = pos
    parent.add_child(mesh)

func _sphere(parent: Node, pos: Vector3, radius: float, color: Color) -> void:
    var mesh := MeshInstance3D.new()
    var shape := SphereMesh.new()
    shape.radius = radius
    shape.height = radius * 2
    mesh.mesh = shape
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mesh.material_override = mat
    mesh.position = pos
    parent.add_child(mesh)

func _world() -> void:
    var sky := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#81c9f6")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color.WHITE
    sky.environment = env
    add_child(sky)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-50, 25, 0)
    add_child(sun)
    _box(self, Vector3(0, -0.4, 0), Vector3(30, 0.7, 24), Color("#57bf76"))
    for x in range(-5, 6):
        for z in range(-4, 5):
            var color := Color("#b7eeac") if (x + z) % 2 == 0 else Color("#a0e6a2")
            _box(self, Vector3(x * UNIT, -0.02, z * UNIT), Vector3(1.92, 0.08, 1.92), color)
    for i in range(8):
        var px := -12.5 if i % 2 == 0 else 12.5
        var pz := -8.0 + i * 2.2
        _box(self, Vector3(px, 0.65, pz), Vector3(0.45, 1.3, 0.45), Color("#a46a48"))
        _sphere(self, Vector3(px, 2.0, pz), 1.0, Color("#32ad6d"))
    robot = Node3D.new()
    robot.position = HOME
    add_child(robot)
    _box(robot, Vector3(0, 0.35, 0), Vector3(1.05, 0.9, 0.85), Color("#f5f8ff"))
    _box(robot, Vector3(0, 0.48, -0.45), Vector3(0.75, 0.43, 0.1), Color("#263a69"))
    _sphere(robot, Vector3(-0.2, 0.48, -0.53), 0.11, Color("#68f4e1"))
    _sphere(robot, Vector3(0.2, 0.48, -0.53), 0.11, Color("#68f4e1"))
    _sphere(robot, Vector3(0, 1.03, 0), 0.15, Color("#ffda70"))
    camera = Camera3D.new()
    camera.fov = 68.0
    camera.current = true
    add_child(camera)
    _update_camera(1.0)
    _goal()

func _goal() -> void:
    for old in get_tree().get_nodes_in_group("goal"):
        old.queue_free()
    var marker := Node3D.new()
    marker.add_to_group("goal")
    marker.position = goals[level]
    add_child(marker)
    _sphere(marker, Vector3(0, 0.55, 0), 0.52, Color("#ffdc55"))
    _sphere(marker, Vector3(0, 1.18, 0), 0.19, Color("#fff9c2"))

func _ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 22)
    margin.add_theme_constant_override("margin_right", 22)
    margin.add_theme_constant_override("margin_top", 20)
    margin.add_theme_constant_override("margin_bottom", 20)
    layer.add_child(margin)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 10)
    margin.add_child(column)
    var title := Label.new()
    title.text = "编程星球 · V0.4.0"
    title.add_theme_font_size_override("font_size", 30)
    title.add_theme_color_override("font_color", Color("#143b62"))
    column.add_child(title)
    mission_label = Label.new()
    mission_label.add_theme_font_size_override("font_size", 20)
    mission_label.add_theme_color_override("font_color", Color("#143b62"))
    column.add_child(mission_label)
    mode_button = Button.new()
    mode_button.text = "切换：积木编程"
    mode_button.custom_minimum_size = Vector2(240, 54)
    mode_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    mode_button.pressed.connect(func() -> void: _set_mode(not exploration))
    column.add_child(mode_button)
    hint_label = Label.new()
    hint_label.add_theme_color_override("font_color", Color("#17385b"))
    hint_label.add_theme_font_size_override("font_size", 17)
    column.add_child(hint_label)
    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_child(spacer)
    var panel := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.07, 0.18, 0.32, 0.87)
    style.set_corner_radius_all(18)
    style.set_content_margin_all(15)
    panel.add_theme_stylebox_override("panel", style)
    column.add_child(panel)
    programming_panel = panel
    var inside := VBoxContainer.new()
    inside.add_theme_constant_override("separation", 10)
    panel.add_child(inside)
    queue_label = Label.new()
    queue_label.add_theme_font_size_override("font_size", 18)
    queue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    inside.add_child(queue_label)
    feedback = Label.new()
    feedback.text = "编排积木，让机器人走向星星！"
    feedback.add_theme_color_override("font_color", Color("#ffdf8d"))
    inside.add_child(feedback)
    var bar := HBoxContainer.new()
    bar.add_theme_constant_override("separation", 8)
    inside.add_child(bar)
    for action in ["前进", "右转", "重复", "撤销", "清空", "执行"]:
        var button := Button.new()
        button.text = action
        button.custom_minimum_size = Vector2(0, 66)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.add_theme_font_size_override("font_size", 18)
        button.pressed.connect(_press.bind(action))
        bar.add_child(button)
        if action == "执行":
            execute_button = button

func _press(action: String) -> void:
    if busy:
        return
    match action:
        "前进", "右转":
            if steps.size() < 20:
                steps.append(action)
        "重复":
            if not steps.is_empty() and steps.size() < 20:
                steps.append(steps.back())
        "撤销":
            if not steps.is_empty():
                steps.pop_back()
        "清空":
            steps.clear()
        "执行":
            if steps.is_empty():
                feedback.text = "先添加积木，再点击执行"
            else:
                _run()
    _refresh()

func _run() -> void:
    busy = true
    execute_button.disabled = true
    robot.position = HOME
    robot.rotation.y = 0
    var pos := HOME
    var direction := 0
    var animation := create_tween()
    var dirs := [Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0)]
    for command in steps:
        if command == "右转":
            direction = (direction + 1) % 4
            animation.tween_property(robot, "rotation:y", -float(direction) * PI / 2.0, 0.35)
        else:
            pos += dirs[direction] * UNIT
            animation.tween_property(robot, "position", pos, 0.42)
    animation.tween_callback(_complete)

func _complete() -> void:
    busy = false
    execute_button.disabled = false
    if robot.position.distance_to(goals[level]) < 0.6:
        feedback.text = "挑战成功！机器人找到星星啦！"
        if level < lessons.size() - 1:
            level += 1
            _goal()
        steps.clear()
    else:
        feedback.text = "还没到星星，再调整积木试试！"
    _refresh()

func _refresh() -> void:
    mission_label.text = "第 %d / %d 关  ·  %s" % [level + 1, lessons.size(), lessons[level]]
    queue_label.text = "积木程序： " + (" → ".join(steps) if not steps.is_empty() else "点击下方积木添加指令")

func _set_mode(want_exploration: bool) -> void:
    exploration = want_exploration
    programming_panel.visible = not exploration
    mode_button.text = "切换：积木编程" if exploration else "切换：自由探索"
    hint_label.text = "左半屏拖动移动 · 右半屏拖动旋转镜头" if exploration else "添加指令后点击执行，抵达星星"
    move_axis = Vector2.ZERO
    move_touch = -1
    look_touch = -1
    _refresh()

func _input(event: InputEvent) -> void:
    if not exploration:
        return
    viewport_width = maxf(1.0, get_viewport().get_visible_rect().size.x)
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            if touch.position.x < viewport_width * 0.48 and move_touch == -1:
                move_touch = touch.index
                move_origin = touch.position
                move_axis = Vector2.ZERO
            elif touch.position.x >= viewport_width * 0.48 and look_touch == -1:
                look_touch = touch.index
        else:
            if touch.index == move_touch:
                move_touch = -1
                move_axis = Vector2.ZERO
            if touch.index == look_touch:
                look_touch = -1
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if drag.index == move_touch:
            move_axis = (drag.position - move_origin) / 100.0
            move_axis = move_axis.limit_length(1.0)
        elif drag.index == look_touch:
            camera_yaw -= drag.relative.x * 0.006
            camera_pitch = clampf(camera_pitch + drag.relative.y * 0.004, 0.12, 1.1)

func _process(delta: float) -> void:
    if exploration and move_axis.length() > 0.08:
        var forward := Vector3(-sin(camera_yaw), 0, -cos(camera_yaw))
        var right := Vector3(cos(camera_yaw), 0, -sin(camera_yaw))
        var movement := right * move_axis.x + forward * -move_axis.y
        movement = movement.normalized()
        robot.position += movement * 4.5 * delta
        robot.position.x = clampf(robot.position.x, -10.0, 10.0)
        robot.position.z = clampf(robot.position.z, -8.0, 8.0)
        robot.rotation.y = atan2(-movement.x, -movement.z)
    _update_camera(delta)

func _update_camera(delta: float) -> void:
    if camera == null or robot == null:
        return
    var focus := robot.global_position + Vector3(0, 1.1, 0)
    var horizontal := cos(camera_pitch) * camera_distance
    var offset := Vector3(sin(camera_yaw) * horizontal, sin(camera_pitch) * camera_distance + 1.0, cos(camera_yaw) * horizontal)
    var target := focus + offset
    camera.global_position = camera.global_position.lerp(target, clampf(delta * 7.0, 0.0, 1.0))
    camera.look_at(focus, Vector3.UP)
