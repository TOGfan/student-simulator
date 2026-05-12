extends StaticBody2D

# This lets you drag and drop your puzzle.tscn into the Inspector!
@export var puzzle_scene: PackedScene 

var player_in_zone = false
# ... (rest of your variables)

# Grab our bubble nodes
@onready var bubble = $SpeechBubble
@onready var dialogue_text = $SpeechBubble/MarginContainer/VBoxContainer/DialogueText
@onready var button_1 = $SpeechBubble/MarginContainer/VBoxContainer/HBoxContainer/Button1
@onready var button_2 = $SpeechBubble/MarginContainer/VBoxContainer/HBoxContainer/Button2

func _ready():
	# Hide the bubble when the game starts
	bubble.visible = false
	
	# Connect our buttons to the functions below
	button_1.pressed.connect(_on_button_1_pressed)
	button_2.pressed.connect(_on_button_2_pressed)

func _on_interact_zone_body_entered(body):
	if body.name == "Player":
		player_in_zone = true

func _on_interact_zone_body_exited(body):
	if body.name == "Player":
		player_in_zone = false
		bubble.visible = false # Auto-close bubble if the player walks away!

func _process(_delta):
	# If player is near, presses interact, AND the bubble isn't already open
	if player_in_zone and Input.is_action_just_pressed("interact") and not bubble.visible:
		open_bubble()

func open_bubble():
	# Set the text
	dialogue_text.text = "Hey! Can you help me over here? The beer vending machine in C-13 is broken! I'm sure the rats ate the cables again... Can you please repair it? I really need a beer before a Math Analysis test!"
	
	button_1.text = "Accept"
	button_2.text = "Reject"
	# Show the bubble
	bubble.visible = true

func _on_button_1_pressed():
	print("Mission Accepted!")
	bubble.visible = false # Hide the speech bubble
	
	if puzzle_scene:
		# 1. Create a brand new CanvasLayer via code
		var puzzle_layer = CanvasLayer.new()
		
		# 2. Set its layer high so it draws ON TOP of your game UI
		puzzle_layer.layer = 100 
		
		# 3. Instantiate the puzzle
		var puzzle = puzzle_scene.instantiate()
		
		# 4. Add the puzzle to the layer, and the layer to the game
		puzzle_layer.add_child(puzzle)
		get_tree().root.add_child(puzzle_layer) 
		
		# 5. Connect the signal! We use .bind(puzzle_layer) to pass the layer 
		# to the function so we can delete it later.
		puzzle.puzzle_finished.connect(_on_puzzle_won.bind(puzzle_layer))
		
		# 6. Pause the RPG world
		get_tree().paused = true 
	else:
		print("ERROR: You forgot to assign the puzzle scene in the Inspector!")

# We create this new function to handle the reward!
func _on_puzzle_won(score, puzzle_layer):
	print("Player beat the minigame with a score of: ", score)
	puzzle_layer.queue_free() 
		# Set the text
	dialogue_text.text = "Thanks! That Piast will for sure help relieve the stress before the exam. I gotta go now, bye!"
	
	button_1.hide();
	button_2.hide();
	# Show the bubble
	bubble.visible = true
	await get_tree().create_timer(3).timeout
	bubble.visible = false
	hide();
	# You can add your reward logic here! (e.g., player.give_gold(100))
	# Note: The puzzle deletes itself and unpauses the game automatically!


func _on_button_2_pressed():
	print("Mission Refused.")
	bubble.visible = false # Close the bubble
