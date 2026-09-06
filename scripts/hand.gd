class_name Hand
extends Node2D

const CARD_SCENE: PackedScene = preload("res://scenes/card.tscn")

@export var max_hand_width: float = 170.0  # Maximum total pixel width the hand can span
@export var default_spacing: float = 26.0  # Normal spacing when holding few cards
@export var initial_cards: int = 0         # Number of random cards to deal on ready

func _ready() -> void:
	for i in range(initial_cards):
		deal_random_card()

func get_cards() -> Array[Card]:
	var cards: Array[Card] = []
	for child in get_children():
		if child is Card:
			cards.append(child)
	return cards

func add_card(card: Card) -> void:
	if card.get_parent() != self:
		if card.get_parent() != null:
			card.reparent(self)
		else:
			add_child(card)
	update_hand_layout()

func spawn_card(rank: Card.Rank, suit: Card.Suit, cardbase: Card.CardBase = Card.CardBase.WHITE) -> Card:
	var new_card: Card = CARD_SCENE.instantiate()
	add_child(new_card)
	new_card.setup_card(rank, suit, cardbase)
	update_hand_layout()
	return new_card

func update_hand_layout() -> void:
	var cards: Array[Card] = get_cards()
	var total_cards: int = cards.size()
	if total_cards == 0:
		return

	var spacing: float = default_spacing
	if total_cards > 1:
		var available_space: float = max_hand_width / float(total_cards - 1)
		spacing = min(default_spacing, available_space)

	var total_span: float = (total_cards - 1) * spacing
	var start_x: float = -total_span / 2.0

	for i in range(total_cards):
		var card: Card = cards[i]
		var target_pos := Vector2(start_x + (i * spacing), 0.0)
		card.z_index = i
		card.base_z_index = i
		card.resting_position = global_position + target_pos

		if not card.is_dragging:
			var tween := create_tween()
			tween.tween_property(card, "position", target_pos, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func make_deck() -> void:
	for i in range(4):
		for j in range(13):
			spawn_card(j as Card.Rank, i as Card.Suit, Card.CardBase.WHITE)

func deal_random_card() -> Card:
	var random_rank := Card.Rank.values().pick_random() as Card.Rank
	var random_suit := Card.Suit.values().pick_random() as Card.Suit
	return spawn_card(random_rank, random_suit, Card.CardBase.WHITE)
