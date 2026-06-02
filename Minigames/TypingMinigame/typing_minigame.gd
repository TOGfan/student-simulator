extends Control

signal puzzle_finished(score)

# The notes the player has to type out
var lecture_slides = [
	"Godot uses Nodes to build scenes.",
	"The Singleton pattern is useful for global data.",
	"Always remember to free your memory!"
]

var current_slide_index = 0
var time_elapsed = 0.0

@onready var target_label = $Panel/TargetText
@onready var input_box = $Panel/LineEdit

func _ready():
	# Make sure this runs even when the main game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS 
	
	# Load the first slide
	target_label.text = lecture_slides[current_slide_index]
	
	# Connect the LineEdit signal to check text every time a key is pressed
	input_box.text_changed.connect(_on_text_changed)
	
	# Automatically click on the text box so the player can start typing instantly
	input_box.grab_focus()

func _process(delta):
	time_elapsed += delta # Track how long they take for the score!

func _on_text_changed(new_text: String):
	# If what they typed perfectly matches the slide text
	if new_text == lecture_slides[current_slide_index]:
		current_slide_index += 1
		input_box.text = "" # Clear the box for the next slide
		
		if current_slide_index >= lecture_slides.size():
			finish_minigame()
		else:
			# Load the next slide
			target_label.text = lecture_slides[current_slide_index]

func finish_minigame():
	# Calculate score based on how fast they typed (faster = higher score)
	var final_score = max(100, 2000 - int(time_elapsed * 20))
	
	# Tell the NPC we won and pass the score! 
	# (The NPC template will handle deleting this scene)
	puzzle_finished.emit(final_score)
