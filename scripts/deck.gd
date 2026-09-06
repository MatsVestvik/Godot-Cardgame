class_name Deck
extends Area2D

signal card_drawn(card: Card, card_data: CardData)

const CARD_SCENE: PackedScene = preload("res://scenes/card.tscn")

@export var target_hand: Hand
@export var can_draw: bool = true

var draw_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []
var is_hovered: bool = false

func _ready() -> void:
	# Connect built-in Area2D signals
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	generate_starter_deck()
	shuffle_draw_pile()

	# Auto-discover hand in scene tree if not explicitly assigned
	if target_hand == null:
		_find_target_hand()

func _find_target_hand() -> void:
	# Try finding Hand in tree
	var tree := get_tree()
	if tree != null:
		var found = tree.root.find_child("Hand", true, false)
		if found is Hand:
			target_hand = found

func _on_mouse_entered() -> void:
	is_hovered = true
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.06, 1.06), 0.08)

func _on_mouse_exited() -> void:
	is_hovered = false
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.08)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not can_draw:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_play_click_animation()
		draw_card()

func _play_click_animation() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.94, 0.94), 0.05)
	tween.tween_property(self, "scale", Vector2(1.06, 1.06) if is_hovered else Vector2(1.0, 1.0), 0.08)

func _play_empty_deck_animation() -> void:
	var orig_pos := position
	var tween := create_tween()
	tween.tween_property(self, "position", orig_pos + Vector2(-3, 0), 0.04)
	tween.tween_property(self, "position", orig_pos + Vector2(3, 0), 0.04)
	tween.tween_property(self, "position", orig_pos + Vector2(-2, 0), 0.04)
	tween.tween_property(self, "position", orig_pos, 0.04)

# 1. Build standard 52-card deck
func generate_starter_deck() -> void:
	draw_pile.clear()
	discard_pile.clear()

	for suit in Card.Suit.values():
		for rank in Card.Rank.values():
			draw_pile.append(CardData.new(rank, suit, Card.CardBase.WHITE))

# 2. Shuffle draw pile
func shuffle_draw_pile() -> void:
	draw_pile.shuffle()

# 3. Reshuffle discard into draw when empty
func recycle_discard_into_draw() -> void:
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	shuffle_draw_pile()

# 4. Draw a single card into the hand
func draw_card() -> Card:
	if target_hand == null:
		_find_target_hand()
		if target_hand == null:
			push_warning("Deck: No target Hand assigned or found in scene!")
			return null

	if draw_pile.is_empty():
		if discard_pile.is_empty():
			print("No cards left to draw!")
			_play_empty_deck_animation()
			return null
		recycle_discard_into_draw()

	var next_card_data: CardData = draw_pile.pop_back()
	var new_card: Card = CARD_SCENE.instantiate()

	# Start card at Deck's world position so it flies into hand
	new_card.global_position = global_position
	new_card.setup_card(next_card_data.rank, next_card_data.suit, next_card_data.cardbase)

	target_hand.add_card(new_card)
	card_drawn.emit(new_card, next_card_data)

	return new_card

# 5. Draw multiple cards (e.g. at round start)
func draw_hand(amount: int) -> void:
	for i in range(amount):
		draw_card()
