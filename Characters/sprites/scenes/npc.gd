extends StaticBody2D

# --- SIGNALS (These are your optional callbacks!) ---
signal mission_accepted
signal mission_refused
signal mission_completed(score)

# --- TEMPLATE VARIABLES ---
@export_category("NPC Settings")
@export var npc_sprite: Texture2D
@export_multiline var dialogue_text_content: String = "I need help with a puzzle!"
@export var button1_text: String = "Accept"
@export var button2_text: String = "Refuse"
@export var disappear_after_finish: bool = true

@export_category("Mission Settings")
@export var puzzle_scene: PackedScene 
@export_multiline var final_message: String = "Thanks! I gotta go now, bye!"
# --------------------------

var player_in_zone = false
var active_puzzle_layer: CanvasLayer = null 

@onready var sprite = $Sprite2D 
@onready var bubble = $SpeechBubble
@onready var dialogue_text = $SpeechBubble/MarginContainer/VBoxContainer/DialogueText
@onready var Button1 = $SpeechBubble/MarginContainer/VBoxContainer/HBoxContainer/Button1
@onready var Button2 = $SpeechBubble/MarginContainer/VBoxContainer/HBoxContainer/Button2

func _ready():
	bubble.visible = false
	
	if npc_sprite:
		sprite.texture = npc_sprite
		
	Button1.text = button1_text
	Button2.text = button2_text
	
	Button1.pressed.connect(_on_button1_pressed)
	Button2.pressed.connect(_on_button2_pressed)

# --- INTERACTION LOGIC ---
func _on_interact_zone_body_entered(body):
	if body.name == "Player":
		player_in_zone = true

func _on_interact_zone_body_exited(body):
	if body.name == "Player":
		player_in_zone = false
		bubble.visible = false

func _process(_delta):
	if player_in_zone and Input.is_action_just_pressed("interact") and not bubble.visible:
		open_bubble()

func open_bubble():
	dialogue_text.text = dialogue_text_content
	
	# Safety check: make sure buttons are visible if we open the bubble!
	Button1.show()
	Button2.show()
	bubble.visible = true

# --- MISSION LOGIC ---
func _on_button1_pressed():
	bubble.visible = false 
	
	# We ALWAYS emit this. We will use this signal to progress normal conversations!
	mission_accepted.emit() 
	
	# ONLY spawn a puzzle if one is actually assigned!
	# Notice we removed the "else" block so it doesn't instantly end the mission.
	if puzzle_scene:
		active_puzzle_layer = CanvasLayer.new()
		active_puzzle_layer.layer = 100 
		var puzzle = puzzle_scene.instantiate()
		active_puzzle_layer.add_child(puzzle)
		get_tree().root.add_child(active_puzzle_layer) 
		puzzle.puzzle_finished.connect(_on_puzzle_won)
		get_tree().paused = true 
		

func _on_button2_pressed():
	bubble.visible = false 
	mission_refused.emit() # Fire the optional custom action!

func _on_puzzle_won(score):
	if active_puzzle_layer != null:
		active_puzzle_layer.queue_free()
		active_puzzle_layer = null 
	
	mission_completed.emit(score)
	
	dialogue_text.text = final_message
	Button1.hide()
	Button2.hide()
	bubble.visible = true
	
	PlayerStats.add_beer(50.0)       # Give 50% of their beer back!
	PlayerStats.add_reputation(10.0) # Add 10% to game completion!
	
	await get_tree().create_timer(3.0).timeout
	bubble.visible = false
	
	# Only hide the NPC if the box is checked!
	if disappear_after_finish:
		queue_free()
	
