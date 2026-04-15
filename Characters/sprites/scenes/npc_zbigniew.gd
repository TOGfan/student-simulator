extends StaticBody2D

var player_in_zone = false

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
	# Add your quest logic here
	bubble.visible = false # Close the bubble

func _on_button_2_pressed():
	print("Mission Refused.")
	bubble.visible = false # Close the bubble
