extends CanvasLayer

@onready var beer_bar = $MarginContainer/VBoxContainer/BeerBar
@onready var rep_bar = $MarginContainer/VBoxContainer/ReputationBar

# Grab our new screens
@onready var overlay = $DarkOverlay
@onready var game_over_panel = $GameOverPanel
@onready var win_panel = $WinPanel
@onready var restart_button = $GameOverPanel/RestartButton
@onready var win_restart_button = $WinPanel/WinRestartButton

func _ready():
	# Hide screens on start
	overlay.visible = false
	game_over_panel.visible = false
	win_panel.visible = false
	
	beer_bar.max_value = PlayerStats.max_beer
	rep_bar.max_value = PlayerStats.max_reputation
	
	PlayerStats.beer_changed.connect(_on_beer_changed)
	PlayerStats.reputation_changed.connect(_on_reputation_changed)
	
	# Connect to our new end-game signals
	PlayerStats.out_of_beer.connect(_on_game_over)
	PlayerStats.game_won.connect(_on_game_won)
	
	# Connect the restart buttons
	restart_button.pressed.connect(_on_restart_pressed)
	win_restart_button.pressed.connect(_on_restart_pressed)
	
	_on_beer_changed(PlayerStats.current_beer)
	_on_reputation_changed(PlayerStats.current_reputation)

func _on_beer_changed(new_value):
	beer_bar.value = new_value

func _on_reputation_changed(new_value):
	rep_bar.value = new_value

# --- END GAME LOGIC ---

func _on_game_over():
	get_tree().paused = true # Freeze the game world
	overlay.visible = true
	game_over_panel.visible = true

func _on_game_won():
	get_tree().paused = true # Freeze the game world
	overlay.visible = true
	win_panel.visible = true

func _on_restart_pressed():
	get_tree().paused = false # Unfreeze the game
	PlayerStats.reset_stats() # Refill the beer and reset reputation!
	get_tree().reload_current_scene() # Reload the map
