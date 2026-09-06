class_name Deck
extends Node2D

const CARD_SCENE: PackedScene = preload("res://scenes/card.tscn")

var draw_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []

@export var hand_container: Node2D # Assign your Hand node in the Inspector

func _ready() -> void:
	generate_starter_deck()
	shuffle_draw_pile()

# 1. Build standard 52-card deck
func generate_starter_deck() -> void:
	draw_pile.clear()
	discard_pile.clear()
	
	for suit in Card.Suit.values():
		for rank in Card.Rank.values():
			draw_pile.append(CardData.new(rank, suit, Card.CardBase.WHITE))

# 2. Shuffle using Godot's built-in array shuffle
func shuffle_draw_pile() -> void:
	draw_pile.shuffle()

# 3. Reshuffle discard into draw when empty
func recycle_discard_into_draw() -> void:
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	shuffle_draw_pile()

# 4. Draw a single card into the hand
func draw_card() -> Card:
	if draw_pile.is_empty():
		if discard_pile.is_empty():
			print("No cards left to draw!")
			return null
		recycle_discard_into_draw()

	# Pop the top card data
	var next_card_data: CardData = draw_pile.pop_back()

	# Instantiate the physical card node
	var new_card: Card = CARD_SCENE.instantiate()
	hand_container.add_child(new_card)
	
	# Spawn at the deck's position so it can animate to hand
	new_card.global_position = global_position
	new_card.setup_card(next_card_data.rank, next_card_data.suit, next_card_data.cardbase)

	# Tell the hand to re-center and slide cards into place
	if hand_container.has_method("update_hand_layout"):
		hand_container.update_hand_layout()

	return new_card

# 5. Draw multiple cards (e.g. at round start)
func draw_hand(amount: int) -> void:
	for i in range(amount):
		draw_card()
