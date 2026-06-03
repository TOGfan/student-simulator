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
		printer_npc.dialogue_text_content = "Hello, do you have anything to print?"
		supervisor_npc.dialogue_text_content = "*Blows cigarette smoke in your face*"
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
		secretary_npc.Button1.hide()
		printer_npc.Button1.hide()
		supervisor_npc.Button1.hide()

		_update_dialogues()
	if quest_step == 6:
		PlayerStats.add_beer(50.0)       # Give 50% of their beer back!
		PlayerStats.add_reputation(35.0) # Add 10% to game completion!

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
			secretary_npc.dialogue_text_content = "Ah, for Jerzy. Why won't he come here himself? Whatever. Why are you showing this on the phone? I need this printed. There's a printer in C-13."
			secretary_npc.button1_text = "On my way!"
		2:
			secretary_npc.dialogue_text_content = "Did you print it yet? Go to C-13."
			
			printer_npc.Button1.show()
			printer_npc.dialogue_text_content = "Alright, I got your E-mail with the documents, they are already printed. Here you go!"
			printer_npc.button1_text = "Thanks!"
		3:
			printer_npc.Button1.hide()
			printer_npc.dialogue_text_content = "Hi, I think I already gave you this print..."
			
			secretary_npc.dialogue_text_content = "Everything seems fine... Now, you gotta take these prints to Jerzy's Supervisor for a signature. He's probably having a smoke in front of D2 as always."
			secretary_npc.button1_text = "Alright, I'll be back soon!"
		4:
			secretary_npc.dialogue_text_content = "You were supposed to get the signature, why are you still here?"
			
			supervisor_npc.Button1.show()
			supervisor_npc.dialogue_text_content = "Ah, Jerzy sent you for a signature? Typical, he always makes people do stuff for him. Hand me the papers."
			supervisor_npc.button1_text = "Give Papers"
		5:
			supervisor_npc.Button1.hide()
			supervisor_npc.dialogue_text_content = "*Blows cigarette smoke in your face*"
			
			secretary_npc.dialogue_text_content = "Got the signature? Fine, documents accepted."
			secretary_npc.button1_text = "Turn in Quest"
		6:
			secretary_npc.Button1.hide()
			secretary_npc.dialogue_text_content = "Do you need anything else?"
			
			jerzy_npc.dialogue_text_content = "Thanks for doing that! I'd rather give out free beer than deal with the Dean's... Actually, that's exactly what I'm doing! Here you go!"
