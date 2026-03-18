extends CharacterBody2D

@export var speed: float = 100.0

# Grab the AnimationPlayer node so we can use it in code
@onready var anim = $AnimationPlayer

# We use this to remember where the player was looking when they stop moving
var current_dir = "down" 

func _physics_process(_delta):
	# 1. Get Input
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	
	# 2. Determine Facing Direction
	if direction.x != 0:
		# If moving right, current_dir is "right", otherwise it's "left"
		current_dir = "right" if direction.x > 0 else "left"
	elif direction.y != 0:
		# If moving down, current_dir is "down", otherwise it's "up"
		current_dir = "down" if direction.y > 0 else "up"
		
	# 3. Play the correct animation
	if velocity.length() == 0:
		# If standing still, play the idle animation for the current direction
		anim.play("idle_" + current_dir)
	else:
		# If moving, play the walk animation for the current direction
		anim.play("walk_" + current_dir)

	# 4. Move the character
	move_and_slide()
