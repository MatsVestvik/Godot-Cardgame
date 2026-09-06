class_name Game
extends Node2D

@onready var energy_manager: EnergyManager = $EnergyManager
@onready var energy_label: Label = $UI/EnergyLabel
@onready var end_turn_button: Button = $UI/EndTurnButton

@export var use_game_cards_deck: bool = true
@export var starter_deck_size: int = 12

func _ready() -> void:
	if energy_manager:
		energy_manager.energy_changed.connect(_on_energy_changed)
		_on_energy_changed(energy_manager.current_energy, energy_manager.max_energy)
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_pressed)

	var deck: Deck = get_node_or_null("Deck") as Deck
	if deck and use_game_cards_deck and deck.custom_deck.is_empty():
		var draw_res: CardResource = load("res://resources/cards/draw_card.tres")
		var energy_res: CardResource = load("res://resources/cards/energy_card.tres")
		var starter: Array[CardResource] = []
		for i in range(8):
			starter.append(draw_res)
		for i in range(4):
			starter.append(energy_res)
		deck.custom_deck = starter
		deck.generate_starter_deck()
		deck.initial_deck_size = deck.get_remaining_count()
		deck.update_stack_visual(false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_on_end_turn_pressed()

func _on_energy_changed(current: int, max_energy: int) -> void:
	if energy_label:
		energy_label.text = "Energy: %d/%d" % [current, max_energy]

func _on_end_turn_pressed() -> void:
	if energy_manager:
		energy_manager.reset_energy()
