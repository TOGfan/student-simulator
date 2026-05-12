extends Node

@export var secretary_npc: StaticBody2D
@export var printer_npc: StaticBody2D
@export var supervisor_npc: StaticBody2D

@onready var jerzy_npc = get_parent()

var quest_step = 0 

func _ready():
	jerzy_npc.mission_accepted.connect(_on_jerzy_talked)
	
	if secretary_npc and printer_npc and supervisor_npc:
		secretary_npc.mission_accepted.connect(_on_secretary_talked)
		printer_npc.mission_accepted.connect(_on_printer_talked)
		supervisor_npc.mission_accepted.connect(_on_supervisor_talked)
		
		# --- INITIALIZATION: Hide characters completely ---
		_set_npc_active(secretary_npc, false)
		_set_npc_active(printer_npc, false)
		_set_npc_active(supervisor_npc, false)
		
		# We still set up their locked dialogue just in case
		secretary_npc.dialogue_text_content = "Please wait your turn."
		printer_npc.dialogue_text_content = "The printer is currently idle."
		supervisor_npc.dialogue_text_content = "I am very busy. Please leave."
		#secretary_npc.Button1.hide()
		#printer_npc.Button1.hide()
		#supervisor_npc.Button1.hide()
		
	else:
		push_error("Quest is missing node links in the Inspector!")

# --- HELPER FUNCTION: Turns NPCs completely on or off ---
func _set_npc_active(npc_node: Node, is_active: bool):
	if is_active:
		npc_node.show() # Makes them visible
		npc_node.process_mode = Node.PROCESS_MODE_INHERIT # Turns on physics and interaction
	else:
		npc_node.hide() # Makes them invisible
		npc_node.process_mode = Node.PROCESS_MODE_DISABLED # Turns off physics and interaction

# --- STATE MACHINE LOGIC ---

func _on_jerzy_talked():
	if quest_step == 0:
		quest_step = 1 
		
		# --- SPAWN THE CHARACTERS: Quest Accepted! ---
		_set_npc_active(secretary_npc, true)
		_set_npc_active(printer_npc, true)
		_set_npc_active(supervisor_npc, true)
		
		_update_dialogues()

func _on_secretary_talked():
	if quest_step == 1:
		quest_step = 2 
		_update_dialogues()
	elif quest_step == 3:
		quest_step = 4 
		_update_dialogues()
	elif quest_step == 5:
		quest_step = 6 
		_update_dialogues()
		print("Quest Fully Complete! Give the player an item here!")

func _on_printer_talked():
	if quest_step == 2:
		quest_step = 3 
		_update_dialogues()

func _on_supervisor_talked():
	if quest_step == 4:
		quest_step = 5 
		_update_dialogues()

# --- DIALOGUE UPDATER ---

func _update_dialogues():
	match quest_step:
		1:
			jerzy_npc.dialogue_text_content = "Hurry up, take that to the Secretary!"
			jerzy_npc.Button1.hide() 
			jerzy_npc.Button2.text = "Leave"
			
			secretary_npc.Button1.show()
			secretary_npc.dialogue_text_content = "Ah, for Jerzy. Why are you showing this on the phone? I need this printed. Go to C-13."
			secretary_npc.button1_text = "On my way!"
		2:
			secretary_npc.dialogue_text_content = "Did you print them yet? Go to C-13."
			
			printer_npc.Button1.show()
			printer_npc.dialogue_text_content = "ERROR: PC LOAD LETTER."
			printer_npc.button1_text = "Smash Print Button"
		3:
			printer_npc.Button1.hide()
			printer_npc.dialogue_text_content = "Printer is out of ink."
			
			secretary_npc.dialogue_text_content = "Great, now take these prints to the Supervisor for a signature."
			secretary_npc.button1_text = "Show Prints"
		4:
			secretary_npc.dialogue_text_content = "Waiting on the supervisor's signature."
			
			supervisor_npc.Button1.show()
			supervisor_npc.dialogue_text_content = "Ah, you need a signature? Hand me the papers."
			supervisor_npc.button1_text = "Give Papers"
		5:
			supervisor_npc.Button1.hide()
			supervisor_npc.dialogue_text_content = "Take those to the Secretary. Do not bother me again."
			
			secretary_npc.dialogue_text_content = "You got the signature! Thank you, documents accepted."
			secretary_npc.button1_text = "Turn in Quest"
		6:
			secretary_npc.Button1.hide()
			secretary_npc.dialogue_text_content = "Your paperwork is finalized. Go study!"
			
			jerzy_npc.dialogue_text_content = "Thanks for doing that! You saved my grade."
