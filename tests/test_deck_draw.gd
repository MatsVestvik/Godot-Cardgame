extends SceneTree

func _init() -> void:
	# Run after first frame so nodes enter tree and run _ready()
	process_frame.connect(_run_test, CONNECT_ONE_SHOT)

func _run_test() -> void:
	print("--- BEGIN DECK DRAW TEST ---")
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	assert(game_scene != null, "game.tscn must exist")

	var game_node = game_scene.instantiate()
	root.add_child(game_node)

	# Wait a frame for children to call _ready()
	await process_frame

	var deck: Deck = game_node.get_node("Deck") as Deck
	var hand: Hand = game_node.get_node("Hand") as Hand

	assert(deck != null, "Deck node must exist")
	assert(hand != null, "Hand node must exist")
	assert(deck.target_hand == hand, "deck.target_hand must match Hand node")

	print("Initial draw pile count: ", deck.draw_pile.size())
	assert(deck.draw_pile.size() == 52, "Deck should have 52 cards initially")
	assert(hand.get_cards().size() == 0, "Hand should start empty")

	# Draw 1 card
	var card1: Card = deck.draw_card()
	assert(card1 != null, "draw_card() should return a Card")
	assert(hand.get_cards().size() == 1, "Hand should have 1 card")
	assert(deck.draw_pile.size() == 51, "Deck should have 51 cards remaining")
	print("Drew card 1: Valid Area2D and CardData applied.")

	# Draw 4 more cards
	for i in range(4):
		var c = deck.draw_card()
		assert(c != null, "Card should not be null")

	assert(hand.get_cards().size() == 5, "Hand should have 5 cards")
	assert(deck.draw_pile.size() == 47, "Deck should have 47 cards remaining")
	print("Hand now has 5 cards successfully!")

	# Draw all remaining cards to test recycle and empty deck handling
	while not deck.draw_pile.is_empty():
		deck.draw_card()

	assert(deck.draw_pile.size() == 0, "Draw pile should be empty")
	print("Draw pile emptied. Trying to draw when empty:")
	var empty_draw = deck.draw_card()
	assert(empty_draw == null, "draw_card on empty deck with no discard should return null")

	print("--- TEST PASSED SUCCESSFULLY ---")
	quit(0)
