extends Node2D

const CARD_SCENE = preload("res://scenes/card.tscn")

var CARDS_HAND = 0
const  CARD_WIDTH = Card.CARD_WIDTH
const MAX_HAND_WIDTH: float = 200.0  # Maximum total pixel width the hand can span
const DEFAULT_SPACING: float = 30.0  # Normal spacing when holding few cards


@onready var hand_container = $Hand # Your HBoxContainer, Control, or Node2D

func _ready() -> void:
	# Example 1: Spawn an Ace of Spades (Foil)
	#spawn_card(Card.Rank.ACE, Card.Suit.SPADES)

	# Example 2: Deal 4 random cards
	for i in range(5):
		deal_random_card()


func spawn_card(rank: Card.Rank, suit: Card.Suit, cardbase: Card.CardBase) -> Card:
	var new_card: Card = CARD_SCENE.instantiate()
	hand_container.add_child(new_card)
	new_card.setup_card(rank, suit, cardbase)
	
	update_hand_layout()
	return new_card


func update_hand_layout() -> void:
	var cards: Array[Node] = get_children()
	var total_cards: int = cards.size()
	if total_cards == 0:
		return

	var max_width: float = 240.0
	var default_spacing: float = 26.0
	var spacing: float = default_spacing

	if total_cards > 1:
		var available_space: float = max_width / float(total_cards - 1)
		spacing = min(default_spacing, available_space)

	var total_span: float = (total_cards - 1) * spacing
	var start_x: float = -total_span / 2.0

	for i in range(total_cards):
		var card := cards[i] as Card
		if not card:
			continue  # Skip any non-card children (like cameras, markers, etc.)

		var target_pos := Vector2(start_x + (i * spacing), 0.0)
		card.z_index = i
		card.base_z_index = i
		card.resting_position = global_position + target_pos
		
		if not card.is_dragging:
			var tween := create_tween()
			tween.tween_property(card, "position", target_pos, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			
func make_deck() -> void:
	# Outer loop: 4 suits (0 to 3)
	for i in range(4):
		# Inner loop: 13 ranks (0 to 12: 2 through Ace)
		for j in range(13):
			spawn_card(j as Card.Rank, i as Card.Suit, 0 as Card.CardBase)


func deal_random_card() -> Card:
	var random_rank := Card.Rank.values().pick_random() as Card.Rank
	var random_suit := Card.Suit.values().pick_random() as Card.Suit
	
	return spawn_card(random_rank, random_suit, 0 as Card.CardBase)
