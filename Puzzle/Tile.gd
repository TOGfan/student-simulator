extends Area2D

signal tile_clicked(grid_pos: Vector2i)

const TILE_BLOCKED := 0
const TILE_STRAIGHT := 1
const TILE_BULB := 2
const TILE_BATTERY := 3
const TILE_CORNER := 4
const TILE_TJUNCTION := 5
const TILE_CROSS := 6

const ROTATION_ORDER := ["top", "right", "bottom", "left"]

@export var tile_size: int = 96

var grid_pos: Vector2i = Vector2i.ZERO
var tile_id: int = TILE_BLOCKED
var tile_rotation: int = 0
var is_fixed: bool = false

var active_connection: bool = false
var bulb_powered: bool = false
var is_selected: bool = false

var connected_sides: Dictionary = {
	"top": false,
	"right": false,
	"bottom": false,
	"left": false,
}

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	input_pickable = true
	_apply_collision_size()
	_refresh_visual_state()


func setup(p_grid_pos: Vector2i, p_tile_id: int, p_rotation: int, p_tile_size: int = 96) -> void:
	grid_pos = p_grid_pos
	tile_id = p_tile_id
	tile_rotation = wrapi(p_rotation, 0, 4)
	tile_size = p_tile_size
	is_fixed = tile_id == TILE_BATTERY or tile_id == TILE_BULB
	active_connection = false
	bulb_powered = false
	is_selected = false
	_apply_collision_size()
	_refresh_visual_state()


func _apply_collision_size() -> void:
	if collision_shape and collision_shape.shape is RectangleShape2D:
		(collision_shape.shape as RectangleShape2D).size = Vector2(tile_size, tile_size)


func rotate_tile() -> void:
	if is_fixed or not is_connectable():
		return

	tile_rotation = (tile_rotation + 1) % 4
	_refresh_visual_state()
	emit_signal("tile_clicked", grid_pos)


func is_connectable() -> bool:
	return tile_id != TILE_BLOCKED


func get_connection_sides() -> Dictionary:
	return connected_sides.duplicate()


func set_active_connection(active: bool) -> void:
	if active_connection == active:
		return

	active_connection = active
	queue_redraw()


func set_bulb_powered(powered: bool) -> void:
	if bulb_powered == powered:
		return

	bulb_powered = powered
	queue_redraw()


func set_selected(selected: bool) -> void:
	if is_selected == selected:
		return

	is_selected = selected
	queue_redraw()


func _refresh_visual_state() -> void:
	connected_sides = _rotated_sides(_base_sides_for_tile(tile_id), tile_rotation)
	queue_redraw()


func _base_sides_for_tile(id: int) -> Dictionary:
	var sides := {
		"top": false,
		"right": false,
		"bottom": false,
		"left": false,
	}

	match id:
		TILE_STRAIGHT:
			sides["top"] = true
			sides["bottom"] = true
		TILE_CORNER:
			sides["top"] = true
			sides["right"] = true
		TILE_TJUNCTION:
			sides["left"] = true
			sides["top"] = true
			sides["right"] = true
		TILE_CROSS:
			sides["top"] = true
			sides["right"] = true
			sides["bottom"] = true
			sides["left"] = true
		TILE_BATTERY, TILE_BULB:
			sides["top"] = true

	return sides


func _rotated_sides(base_sides: Dictionary, rotation_steps: int) -> Dictionary:
	var rotated := {}
	var normalized_steps := wrapi(rotation_steps, 0, 4)

	for index in ROTATION_ORDER.size():
		var side_to: String = ROTATION_ORDER[index]
		var from_index := posmod(index - normalized_steps, ROTATION_ORDER.size())
		var side_from: String = ROTATION_ORDER[from_index]
		rotated[side_to] = base_sides.get(side_from, false)

	return rotated


func _draw() -> void:
	var half := float(tile_size) * 0.5
	var tile_rect := Rect2(Vector2(-half, -half), Vector2(tile_size, tile_size))

	var border_color := Color(0.16, 0.16, 0.18)
	var blocked_color := Color(0.42, 0.28, 0.16)
	var usable_color := Color(0.82, 0.84, 0.86)

	if tile_id == TILE_BLOCKED:
		draw_rect(tile_rect, blocked_color, true)
		draw_rect(tile_rect, border_color, false, 2.0)
		draw_line(Vector2(-half + 8.0, -half + 8.0), Vector2(half - 8.0, half - 8.0), Color(0.28, 0.17, 0.10), 3.0, true)
		draw_line(Vector2(half - 8.0, -half + 8.0), Vector2(-half + 8.0, half - 8.0), Color(0.28, 0.17, 0.10), 3.0, true)
		return

	draw_rect(tile_rect, usable_color, true)
	draw_rect(tile_rect, border_color, false, 2.0)

	if is_selected:
		draw_rect(tile_rect.grow(-3.0), Color(0.18, 0.48, 1.0), false, 4.0)

	if active_connection:
		draw_rect(tile_rect.grow(-5.0), Color(1.0, 0.94, 0.55, 0.22), true)

	var cable_color_off := Color(0.23, 0.25, 0.28)
	var cable_color_on := Color(1.0, 0.84, 0.20)
	var cable_color := cable_color_on if active_connection else cable_color_off

	if tile_id == TILE_BATTERY:
		cable_color = Color(0.18, 0.62, 0.25)
	elif tile_id == TILE_BULB and bulb_powered:
		cable_color = Color(1.0, 0.90, 0.30)

	_draw_connector("top", half, cable_color)
	_draw_connector("right", half, cable_color)
	_draw_connector("bottom", half, cable_color)
	_draw_connector("left", half, cable_color)

	if is_connectable():
		draw_circle(Vector2.ZERO, 9.0, cable_color)

	if tile_id == TILE_BATTERY:
		_draw_battery_icon()
	elif tile_id == TILE_BULB:
		_draw_bulb_icon()


func _draw_connector(side: String, half: float, color: Color) -> void:
	if not connected_sides.get(side, false):
		return

	var inner := 8.0
	var endpoint := Vector2.ZERO
	match side:
		"top":
			endpoint = Vector2(0.0, -half + inner)
		"right":
			endpoint = Vector2(half - inner, 0.0)
		"bottom":
			endpoint = Vector2(0.0, half - inner)
		"left":
			endpoint = Vector2(-half + inner, 0.0)

	draw_line(Vector2.ZERO, endpoint, color, 10.0, true)


func _draw_battery_icon() -> void:
	var body := Rect2(Vector2(-15.0, -10.0), Vector2(30.0, 20.0))
	draw_rect(body, Color(0.14, 0.54, 0.22), true)
	draw_rect(body, Color(0.06, 0.27, 0.11), false, 2.0)
	draw_rect(Rect2(Vector2(15.0, -4.0), Vector2(6.0, 8.0)), Color(0.06, 0.27, 0.11), true)
	draw_rect(Rect2(Vector2(-10.0, -5.0), Vector2(8.0, 10.0)), Color(0.35, 0.80, 0.42), true)


func _draw_bulb_icon() -> void:
	if bulb_powered:
		draw_circle(Vector2(0.0, -3.0), 18.0, Color(1.0, 0.95, 0.35, 0.20))

	var bulb_color := Color(1.0, 0.91, 0.35) if bulb_powered else Color(0.62, 0.62, 0.66)
	draw_circle(Vector2(0.0, -3.0), 12.0, bulb_color)
	draw_rect(Rect2(Vector2(-6.0, 7.0), Vector2(12.0, 8.0)), Color(0.34, 0.34, 0.38), true)
	draw_rect(Rect2(Vector2(-8.0, 5.0), Vector2(16.0, 2.0)), Color(0.26, 0.26, 0.30), true)
