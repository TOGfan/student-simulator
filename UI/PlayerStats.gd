extends Node

# Signals to tell the UI when to update
signal beer_changed(new_value)
signal reputation_changed(new_value)
signal out_of_beer # Optional: Use this later to trigger a "Game Over" or slow movement!

var max_beer: float = 100.0
var current_beer: float = 100.0
var beer_drain_rate: float = 2.0 # How much beer you lose per second

var max_reputation: float = 100.0
var current_reputation: float = 0.0

func _process(delta):
	# Slowly drain the beer over time
	if current_beer > 0:
		current_beer -= beer_drain_rate * delta
		beer_changed.emit(current_beer)
		
		if current_beer <= 0:
			current_beer = 0
			out_of_beer.emit()

# Quests will call this function to give you a reward
func add_beer(amount: float):
	current_beer += amount
	if current_beer > max_beer:
		current_beer = max_beer
	beer_changed.emit(current_beer)

# Quests will call this function to progress the game
func add_reputation(amount: float):
	current_reputation += amount
	if current_reputation > max_reputation:
		current_reputation = max_reputation
	reputation_changed.emit(current_reputation)
