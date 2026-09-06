class_name Game
extends Node2D

@onready var energy_manager: EnergyManager = $EnergyManager
@onready var energy_label: Label = $UI/EnergyLabel
@onready var end_turn_button: Button = $UI/EndTurnButton
@onready var table: Table = get_node_or_null("Table") as Table
@onready var deck: Deck = get_node_or_null("Deck") as Deck
@onready var hand: Hand = get_node_or_null("Hand") as Hand

@export var use_game_cards_deck: bool = true
@export var starter_deck_size: int = 60
@export var draw_card_count: int = 30
@export var energy_card_count: int = 30
@export var hand_starting_cards: int = 5
@export var discard_hand_on_round_end: bool = false
@export var auto_start_first_round: bool = true

var current_round: int = 0

func _ready() -> void:
	if energy_manager:
		energy_manager.energy_changed.connect(_on_energy_changed)
		_on_energy_changed(energy_manager.current_energy, energy_manager.max_energy)
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_pressed)

	if deck == null:
		deck = get_node_or_null("Deck") as Deck
	if table == null:
		table = get_node_or_null("Table") as Table
	if hand == null:
		hand = get_node_or_null("Hand") as Hand

	if deck and use_game_cards_deck and deck.custom_deck.is_empty():
		build_and_shuffle_starter_deck()

	if auto_start_first_round and use_game_cards_deck:
		start_round()

func build_and_shuffle_starter_deck() -> void:
	var draw_res: CardResource = load("res://resources/cards/draw_card.tres")
	var energy_res: CardResource = load("res://resources/cards/energy_card.tres")
	var starter: Array[CardResource] = []
	for i in range(draw_card_count):
		starter.append(draw_res)
	for i in range(energy_card_count):
		starter.append(energy_res)
	starter.shuffle()
	deck.custom_deck = starter
	deck.generate_starter_deck()
	deck.shuffle_draw_pile()
	deck.initial_deck_size = deck.get_remaining_count()
	deck.update_stack_visual(false)

func start_round() -> void:
	current_round += 1
	refill_hand_to_starting_size()

func refill_hand_to_starting_size() -> void:
	if hand == null or deck == null:
		return

	if discard_hand_on_round_end:
		var cards_to_discard := hand.get_cards()
		for c in cards_to_discard:
			if "card_data" in c and c.card_data != null:
				deck.discard_pile.append(c.card_data)
			hand.remove_card(c)
			c.queue_free()

	var current_count: int = hand.get_cards().size()
	var needed: int = hand_starting_cards - current_count
	if needed > 0:
		deck.draw_hand(needed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_on_end_turn_pressed()

func _on_energy_changed(current: int, max_energy: int) -> void:
	if energy_label:
		energy_label.text = "Energy: %d/%d" % [current, max_energy]

func _on_end_turn_pressed() -> void:
	if table:
		table.clear_table(deck)

	# Energy persists across rounds (no reset)
	start_round()
