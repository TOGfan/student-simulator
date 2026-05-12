extends Node2D

signal puzzle_finished(final_score) # ADD THIS LINE

const TILE_BLOCKED := 0
# ... (rest of your constants)
const TILE_STRAIGHT := 1
const TILE_BULB := 2
const TILE_BATTERY := 3

const SIDE_TO_OFFSET := {
	"top": Vector2i(0, -1),
	"right": Vector2i(1, 0),
	"bottom": Vector2i(0, 1),
	"left": Vector2i(-1, 0),
}

const OPPOSITE_SIDE := {
	"top": "bottom",
	"right": "left",
	"bottom": "top",
	"left": "right",
}

const STATE_PLAYING := "playing"
const STATE_LEVEL_COMPLETE := "level_complete"
const STATE_LEVEL_FAILED := "level_failed"
const STATE_GAME_COMPLETE := "game_complete"

const LEVELS_PATH := "res://Puzzle/levels/levels.json"

const ACTION_MOVE_UP := "puzzle_move_up"
const ACTION_MOVE_RIGHT := "puzzle_move_right"
const ACTION_MOVE_DOWN := "puzzle_move_down"
const ACTION_MOVE_LEFT := "puzzle_move_left"
const ACTION_ROTATE := "puzzle_rotate"

@export var tile_scene: PackedScene
@export var cell_size: int = 96
@export var default_level_time: float = 60.0
@export var log_input_events: bool = true

@onready var grid_root: Node2D = $GridRoot
@onready var timer_node: Timer = $LevelTimer
@onready var level_label: Label = $CanvasLayer/UIRoot/Layout/TopBar/TopRow/LevelLabel
@onready var score_label: Label = $CanvasLayer/UIRoot/Layout/TopBar/TopRow/ScoreLabel
@onready var moves_label: Label = $CanvasLayer/UIRoot/Layout/TopBar/TopRow/MovesLabel
@onready var timer_bar: ProgressBar = $CanvasLayer/UIRoot/Layout/TimerBar
@onready var status_label: Label = $CanvasLayer/UIRoot/Layout/StatusLabel
@onready var action_button: Button = $CanvasLayer/UIRoot/Layout/ActionButton

var levels: Array = []
var level_grid: Array = []

var battery_tile_pos: Vector2i = Vector2i(-1, -1)
var bulb_tile_pos: Vector2i = Vector2i(-1, -1)

var current_level_index: int = 0
var total_score: int = 0
var rotation_count: int = 0
var game_state: String = STATE_PLAYING

var selected_tile_pos: Vector2i = Vector2i(-1, -1)
var grid_origin: Vector2 = Vector2.ZERO
var grid_rows: int = 0
var grid_cols: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # ADD THIS LINE
	
	_ensure_input_actions()
	# ... (rest of your ready function)
	action_button.pressed.connect(_on_action_button_pressed)
	timer_node.timeout.connect(_on_level_timer_timeout)
	_load_levels()
	_log_input("GameScene ready. Keyboard: Arrows/WASD, Rotate: Space/Enter")

	if levels.is_empty():
		_status_text("No levels found. Add data in res://Puzzle/levels/levels.json")
		return

	_start_level(0)


func _process(_delta: float) -> void:
	if not timer_node.is_stopped():
		timer_bar.value = timer_node.time_left


func _input(event: InputEvent) -> void:
	if game_state != STATE_PLAYING:
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_grid_pos := _grid_pos_from_screen(mouse_event.position)
			if _is_valid_grid_pos(mouse_grid_pos):
				_log_input("Mouse rotate at %s" % [str(mouse_grid_pos)])
				_rotate_tile_at(mouse_grid_pos)
				get_viewport().set_input_as_handled()
			return

	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event
		if touch_event.pressed:
			var touch_grid_pos := _grid_pos_from_screen(touch_event.position)
			if _is_valid_grid_pos(touch_grid_pos):
				_log_input("Touch rotate at %s" % [str(touch_grid_pos)])
				_rotate_tile_at(touch_grid_pos)
				get_viewport().set_input_as_handled()
			return

	if event is InputEventKey:
		var key_event: InputEventKey = event
		if not key_event.pressed or key_event.echo:
			return

		_log_input("Raw key event keycode=%d physical=%d" % [key_event.keycode, key_event.physical_keycode])

		var consumed := false
		if _event_matches_any_key(key_event, [KEY_UP, KEY_W]):
			_move_selection(Vector2i(0, -1))
			consumed = true
		elif _event_matches_any_key(key_event, [KEY_RIGHT, KEY_D]):
			_move_selection(Vector2i(1, 0))
			consumed = true
		elif _event_matches_any_key(key_event, [KEY_DOWN, KEY_S]):
			_move_selection(Vector2i(0, 1))
			consumed = true
		elif _event_matches_any_key(key_event, [KEY_LEFT, KEY_A]):
			_move_selection(Vector2i(-1, 0))
			consumed = true
		elif _event_matches_any_key(key_event, [KEY_SPACE, KEY_ENTER]):
			_rotate_tile_at(selected_tile_pos)
			consumed = true

		if consumed:
			get_viewport().set_input_as_handled()


func _load_levels() -> void:
	levels.clear()

	if FileAccess.file_exists(LEVELS_PATH):
		var file := FileAccess.open(LEVELS_PATH, FileAccess.READ)
		if file:
			var parsed = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY and parsed.has("levels"):
				levels = parsed["levels"]
			elif typeof(parsed) == TYPE_ARRAY:
				levels = parsed
			elif typeof(parsed) == TYPE_DICTIONARY:
				levels = [parsed]

	if levels.is_empty():
		levels = _default_levels()


func _start_level(level_index: int) -> void:
	if level_index < 0 or level_index >= levels.size():
		return

	current_level_index = level_index
	rotation_count = 0
	battery_tile_pos = Vector2i(-1, -1)
	bulb_tile_pos = Vector2i(-1, -1)
	game_state = STATE_PLAYING
	action_button.visible = false

	var level_data: Dictionary = levels[level_index]
	_load_level(level_data)
	_initialize_selection()

	var level_time := float(level_data.get("time_limit", default_level_time))
	timer_node.wait_time = max(level_time, 1.0)
	timer_node.start()

	timer_bar.max_value = timer_node.wait_time
	timer_bar.value = timer_node.time_left

	_status_text("Connect battery to bulb before time runs out. Click tile or use arrows/WASD + Space/Enter.")
	_update_header_labels()
	_solve_circuit()


func _load_level(level_data: Dictionary) -> void:
	for child in grid_root.get_children():
		child.free()

	level_grid.clear()
	_clear_selection()

	var grid_data: Array = level_data.get("grid", [])
	var rotations_data: Array = level_data.get("rotations", [])

	if grid_data.is_empty():
		grid_rows = 0
		grid_cols = 0
		return

	var rows := grid_data.size()
	var cols := 0
	if typeof(grid_data[0]) == TYPE_ARRAY:
		cols = grid_data[0].size()

	for y in rows:
		var grid_row: Array = grid_data[y]
		var scene_row: Array = []

		for x in cols:
			var tile_id := int(grid_row[x])
			var tile_rotation := 0
			if y < rotations_data.size() and typeof(rotations_data[y]) == TYPE_ARRAY:
				var rot_row: Array = rotations_data[y]
				if x < rot_row.size():
					tile_rotation = int(rot_row[x])

			var tile := _spawn_tile(Vector2i(x, y), tile_id, tile_rotation)
			scene_row.append(tile)

			if tile_id == TILE_BATTERY:
				battery_tile_pos = Vector2i(x, y)
			elif tile_id == TILE_BULB:
				bulb_tile_pos = Vector2i(x, y)

		level_grid.append(scene_row)

	_position_grid(rows, cols)


func _spawn_tile(grid_pos: Vector2i, tile_id: int, tile_rotation: int) -> Node:
	if tile_scene == null:
		push_error("Tile scene missing. Set tile_scene on GameScene node.")
		return null

	var tile := tile_scene.instantiate()
	grid_root.add_child(tile)

	tile.position = Vector2(float(grid_pos.x * cell_size), float(grid_pos.y * cell_size))
	tile.call("setup", grid_pos, tile_id, tile_rotation, cell_size)
	tile.connect("tile_clicked", Callable(self, "_on_tile_clicked"))

	return tile


func _position_grid(rows: int, cols: int) -> void:
	var total_size := Vector2(float(cols * cell_size), float(rows * cell_size))
	var origin := -total_size * 0.5 + Vector2(float(cell_size), float(cell_size)) * 0.5
	grid_root.position = get_viewport_rect().size * Vector2(0.5, 0.56)
	grid_origin = origin
	grid_rows = rows
	grid_cols = cols

	for row in level_grid:
		for tile in row:
			if tile:
				var tile_pos: Vector2i = tile.get("grid_pos")
				tile.position = origin + Vector2(tile_pos.x * cell_size, tile_pos.y * cell_size)


func _on_tile_clicked(grid_pos: Vector2i) -> void:
	if game_state != STATE_PLAYING:
		return

	_set_selected_tile(grid_pos)
	rotation_count += 1
	_update_header_labels()
	_solve_circuit()


func _solve_circuit() -> void:
	_reset_connection_state()

	if game_state != STATE_PLAYING:
		return

	if not _is_valid_grid_pos(battery_tile_pos) or not _is_valid_grid_pos(bulb_tile_pos):
		return

	var queue: Array[Vector2i] = [battery_tile_pos]
	var visited := {}
	visited[battery_tile_pos] = true
	var reached_bulb := false

	while not queue.is_empty():
		var current_pos: Vector2i = queue.pop_front()
		var current_tile: Node = _tile_at(current_pos)
		if current_tile == null:
			continue

		current_tile.call("set_active_connection", true)
		if current_pos == bulb_tile_pos:
			reached_bulb = true

		for neighbor_pos in _connected_neighbors(current_tile):
			if not visited.has(neighbor_pos):
				visited[neighbor_pos] = true
				queue.push_back(neighbor_pos)

	if reached_bulb:
		var bulb_tile: Node = _tile_at(bulb_tile_pos)
		if bulb_tile:
			bulb_tile.call("set_bulb_powered", true)
		_on_level_completed(visited.size())


func _connected_neighbors(tile: Node) -> Array:
	var result: Array = []
	if tile == null:
		return result

	if not tile.call("is_connectable"):
		return result

	var sides: Dictionary = tile.call("get_connection_sides")
	var tile_pos: Vector2i = tile.get("grid_pos")

	for side in SIDE_TO_OFFSET.keys():
		if not sides.get(side, false):
			continue

		var neighbor_pos: Vector2i = tile_pos + SIDE_TO_OFFSET[side]
		var neighbor_tile: Node = _tile_at(neighbor_pos)
		if neighbor_tile == null:
			continue
		if not neighbor_tile.call("is_connectable"):
			continue

		var neighbor_sides: Dictionary = neighbor_tile.call("get_connection_sides")
		var opposite_side: String = OPPOSITE_SIDE[side]
		if neighbor_sides.get(opposite_side, false):
			result.append(neighbor_pos)

	return result


func _reset_connection_state() -> void:
	for row in level_grid:
		for tile in row:
			if tile:
				tile.call("set_active_connection", false)
				if int(tile.get("tile_id")) == TILE_BULB:
					tile.call("set_bulb_powered", false)


func _on_level_completed(powered_tiles: int) -> void:
	if game_state != STATE_PLAYING:
		return

	game_state = STATE_LEVEL_COMPLETE
	timer_node.stop()

	var time_bonus: int = int(timer_node.time_left * 10.0)
	var efficiency_bonus: int = maxi(0, 120 - rotation_count * 3)
	var network_bonus: int = powered_tiles * 4
	var level_score: int = time_bonus + efficiency_bonus + network_bonus
	total_score += level_score

	_update_header_labels()
	_status_text("Circuit complete! +%d points" % level_score)

	if current_level_index + 1 < levels.size():
		action_button.text = "Next Level"
	else:
		action_button.text = "Finish"
	action_button.visible = true


func _on_level_timer_timeout() -> void:
	if game_state != STATE_PLAYING:
		return

	game_state = STATE_LEVEL_FAILED
	_status_text("Time is up. Retry the level.")
	action_button.text = "Retry Level"
	action_button.visible = true


func _on_action_button_pressed() -> void:
	match game_state:
		STATE_LEVEL_COMPLETE:
			if current_level_index + 1 < levels.size():
				_start_level(current_level_index + 1)
			else:
				game_state = STATE_GAME_COMPLETE
				_status_text("All levels complete! Final score: %d" % total_score)
				action_button.text = "Finish Mission" # Changed button text
				action_button.visible = true
		STATE_LEVEL_FAILED:
			_start_level(current_level_index)
		STATE_GAME_COMPLETE:
			# NEW CODE HERE: Close puzzle and return to main game
			puzzle_finished.emit(total_score) # Send the score back to the RPG
			get_tree().paused = false         # Unpause the RPG world
			queue_free()                      # Delete the puzzle scene


func _update_header_labels() -> void:
	level_label.text = "Level %d/%d" % [current_level_index + 1, max(1, levels.size())]
	score_label.text = "Score: %d" % total_score
	moves_label.text = "Rotations: %d" % rotation_count


func _status_text(text_value: String) -> void:
	status_label.text = text_value


func _is_valid_grid_pos(pos: Vector2i) -> bool:
	if pos.y < 0 or pos.y >= level_grid.size():
		return false
	if pos.x < 0 or pos.x >= level_grid[pos.y].size():
		return false
	return true


func _tile_at(pos: Vector2i) -> Node:
	if not _is_valid_grid_pos(pos):
		return null
	return level_grid[pos.y][pos.x]


func _grid_pos_from_screen(screen_pos: Vector2) -> Vector2i:
	if grid_rows <= 0 or grid_cols <= 0:
		return Vector2i(-1, -1)

	var board_top_left := grid_root.global_position + grid_origin - Vector2(float(cell_size), float(cell_size)) * 0.5
	var local := screen_pos - board_top_left

	var x := int(floor(local.x / float(cell_size)))
	var y := int(floor(local.y / float(cell_size)))
	return Vector2i(x, y)


func _ensure_input_actions() -> void:
	_ensure_action_with_keys(ACTION_MOVE_UP, [KEY_UP, KEY_W])
	_ensure_action_with_keys(ACTION_MOVE_RIGHT, [KEY_RIGHT, KEY_D])
	_ensure_action_with_keys(ACTION_MOVE_DOWN, [KEY_DOWN, KEY_S])
	_ensure_action_with_keys(ACTION_MOVE_LEFT, [KEY_LEFT, KEY_A])
	_ensure_action_with_keys(ACTION_ROTATE, [KEY_SPACE, KEY_ENTER])


func _ensure_action_with_keys(action_name: String, keycodes: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for keycode in keycodes:
		var has_keycode := false
		for action_event in InputMap.action_get_events(action_name):
			if action_event is InputEventKey and action_event.keycode == int(keycode):
				has_keycode = true
				break

		if not has_keycode:
			var key_event := InputEventKey.new()
			key_event.keycode = int(keycode)
			key_event.physical_keycode = int(keycode)
			InputMap.action_add_event(action_name, key_event)


func _handle_keyboard_controls() -> void:
	if Input.is_action_just_pressed(ACTION_MOVE_UP):
		_log_input("Keyboard move: up")
		_move_selection(Vector2i(0, -1))

	if Input.is_action_just_pressed(ACTION_MOVE_RIGHT):
		_log_input("Keyboard move: right")
		_move_selection(Vector2i(1, 0))

	if Input.is_action_just_pressed(ACTION_MOVE_DOWN):
		_log_input("Keyboard move: down")
		_move_selection(Vector2i(0, 1))

	if Input.is_action_just_pressed(ACTION_MOVE_LEFT):
		_log_input("Keyboard move: left")
		_move_selection(Vector2i(-1, 0))

	if Input.is_action_just_pressed(ACTION_ROTATE):
		_log_input("Keyboard rotate at %s" % [str(selected_tile_pos)])
		_rotate_tile_at(selected_tile_pos)


func _log_input(message: String) -> void:
	if log_input_events:
		print("[Input] %s" % message)


func _event_matches_any_key(key_event: InputEventKey, keys: Array) -> bool:
	for keycode in keys:
		if key_event.keycode == int(keycode) or key_event.physical_keycode == int(keycode):
			return true
	return false


func _is_rotatable_tile(tile: Node) -> bool:
	if tile == null:
		return false
	if not tile.call("is_connectable"):
		return false
	return not bool(tile.get("is_fixed"))


func _set_selected_tile(pos: Vector2i) -> void:
	if not _is_valid_grid_pos(pos):
		return

	var next_tile: Node = _tile_at(pos)
	if not _is_rotatable_tile(next_tile):
		return

	if _is_valid_grid_pos(selected_tile_pos):
		var previous_tile: Node = _tile_at(selected_tile_pos)
		if previous_tile:
			previous_tile.call("set_selected", false)

	selected_tile_pos = pos
	next_tile.call("set_selected", true)


func _clear_selection() -> void:
	if _is_valid_grid_pos(selected_tile_pos):
		var previous_tile: Node = _tile_at(selected_tile_pos)
		if previous_tile:
			previous_tile.call("set_selected", false)

	selected_tile_pos = Vector2i(-1, -1)


func _initialize_selection() -> void:
	_clear_selection()

	for y in grid_rows:
		for x in grid_cols:
			var pos := Vector2i(x, y)
			if _is_rotatable_tile(_tile_at(pos)):
				_set_selected_tile(pos)
				return


func _find_next_rotatable_pos(start_pos: Vector2i, step: Vector2i) -> Vector2i:
	if grid_rows <= 0 or grid_cols <= 0:
		return Vector2i(-1, -1)

	var current := start_pos
	for _i in grid_rows * grid_cols:
		current = Vector2i(posmod(current.x + step.x, grid_cols), posmod(current.y + step.y, grid_rows))
		if _is_rotatable_tile(_tile_at(current)):
			return current

	return start_pos


func _move_selection(step: Vector2i) -> void:
	if grid_rows <= 0 or grid_cols <= 0:
		return

	if not _is_valid_grid_pos(selected_tile_pos):
		_initialize_selection()
		return

	var next_pos := _find_next_rotatable_pos(selected_tile_pos, step)
	_set_selected_tile(next_pos)


func _rotate_tile_at(pos: Vector2i) -> void:
	if not _is_valid_grid_pos(pos):
		return

	var tile: Node = _tile_at(pos)
	if not _is_rotatable_tile(tile):
		return

	_set_selected_tile(pos)
	tile.call("rotate_tile")


func _default_levels() -> Array:
	return [
		{
			"id": 1,
			"time_limit": 60,
			"grid": [
				[0, 0, 0, 0, 4, 2],
				[0, 0, 0, 4, 1, 0],
				[0, 0, 4, 1, 4, 0],
				[0, 4, 1, 0, 1, 4],
				[0, 0, 1, 0, 0, 1],
				[3, 1, 4, 1, 0, 0]
			],
			"rotations": [
				[0, 0, 0, 0, 0, 3],
				[0, 0, 0, 2, 1, 0],
				[0, 0, 3, 2, 1, 0],
				[0, 0, 0, 0, 1, 2],
				[0, 0, 2, 0, 0, 0],
				[1, 0, 1, 0, 0, 0]
			]
		},
		{
			"id": 2,
			"time_limit": 75,
			"grid": [
				[0, 0, 0, 0, 0, 0, 0],
				[0, 0, 0, 6, 0, 0, 0],
				[0, 0, 0, 0, 4, 1, 2],
				[0, 1, 0, 0, 1, 0, 0],
				[0, 5, 6, 1, 4, 5, 0],
				[0, 0, 1, 0, 0, 4, 1],
				[3, 1, 4, 0, 0, 0, 0]
			],
			"rotations": [
				[0, 0, 0, 0, 0, 0, 0],
				[0, 0, 0, 1, 0, 0, 0],
				[0, 0, 0, 0, 3, 0, 3],
				[0, 2, 0, 0, 3, 0, 0],
				[0, 1, 2, 0, 1, 0, 0],
				[0, 0, 1, 0, 0, 1, 2],
				[1, 0, 1, 0, 0, 0, 0]
			]
		}
	]
