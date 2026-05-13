extends CanvasLayer

@onready var beer_bar = $MarginContainer/VBoxContainer/BeerBar
@onready var rep_bar = $MarginContainer/VBoxContainer/ReputationBar

func _ready():
	# Setup maximums
	beer_bar.max_value = PlayerStats.max_beer
	rep_bar.max_value = PlayerStats.max_reputation
	
	# Connect to the global signals!
	PlayerStats.beer_changed.connect(_on_beer_changed)
	PlayerStats.reputation_changed.connect(_on_reputation_changed)
	
	# Set initial visuals on load
	_on_beer_changed(PlayerStats.current_beer)
	_on_reputation_changed(PlayerStats.current_reputation)

func _on_beer_changed(new_value):
	beer_bar.value = new_value

func _on_reputation_changed(new_value):
	rep_bar.value = new_value
