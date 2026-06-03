extends Node

signal beer_changed(new_value)
signal reputation_changed(new_value)
signal out_of_beer 
signal game_won # ADD THIS NEW SIGNAL!

var max_beer: float = 100.0
var current_beer: float = 100.0
var beer_drain_rate: float = 1.0 

var max_reputation: float = 100.0
var current_reputation: float = 0.0

func _process(delta):
	if current_beer > 0:
		current_beer -= beer_drain_rate * delta
		beer_changed.emit(current_beer)
		
		if current_beer <= 0:
			current_beer = 0
			out_of_beer.emit()

func add_beer(amount: float):
	current_beer += amount
	if current_beer > max_beer:
		current_beer = max_beer
	beer_changed.emit(current_beer)

func add_reputation(amount: float):
	current_reputation += amount
	if current_reputation >= max_reputation:
		current_reputation = max_reputation
		game_won.emit() # FIRE THE WIN SIGNAL!
	reputation_changed.emit(current_reputation)

# We need this so when the player restarts, their fuel goes back to 100!
func reset_stats():
	current_beer = max_beer
	current_reputation = 0.0
