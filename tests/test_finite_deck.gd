extends SceneTree

func _init() -> void:
	process_frame.connect(_run_test, CONNECT_ONE_SHOT)

func _run_test() -> void:
	print("--- BEGIN FINITE DECK TEST ---")
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	var game_node = game_scene.instantiate()
	root.add_child(game_node)

	await process_frame
	await process_frame

	var deck: Deck = game_node.get_node("Deck") as Deck
	assert(deck != null, "Deck should exist")

	# 1. Verify initial full deck state
	assert(deck.draw_pile.size() == 52, "Deck should have 52 cards initially")
	assert(deck.top_card_sprite.visible == true, "TopCard should be visible initially")
	assert(deck.current_stack_height == 7, "TopCard should be at maximum height (7)")
	assert(deck.count_label.text == "52", "Count label should display 52")
	print("Initial state verified: 52 cards, height 7.")

	# 2. Draw 26 cards (50%)
	for i in range(26):
		deck.draw_card()

	assert(deck.draw_pile.size() == 26, "Deck should have 26 cards remaining")
	assert(deck.current_stack_height == 4, "Deck height should decrease proportionally to 4")
	assert(deck.count_label.text == "26", "Count label should display 26")
	print("Mid-way state verified: 26 cards, deck visibly thinned to height 4.")

	# 3. Draw 25 more cards (1 card left)
	for i in range(25):
		deck.draw_card()

	assert(deck.draw_pile.size() == 1, "Deck should have 1 card remaining")
	assert(deck.current_stack_height == 1, "Single card height should be 1")
	assert(deck.count_label.text == "1", "Count label should display 1")
	print("Single card state verified: height 1, count 1.")

	# 4. Draw the very last card (0 cards left)
	var last_card = deck.draw_card()
	assert(last_card != null, "Last card should be successfully drawn")
	assert(deck.draw_pile.size() == 0, "Deck should now be completely empty")
	assert(deck.current_stack_height == 0, "Current stack height should be 0")
	assert(deck.top_card_sprite.visible == false, "TopCard should be hidden when empty")
	assert(deck.shadow_sprite.visible == false, "Shadow should be hidden when empty")
	assert(deck.count_label.text == "0", "Count label should display 0")
	print("Empty state verified: TopCard and stack hidden, count 0.")

	# 5. Attempt drawing from empty deck (finite deck behavior)
	var no_card = deck.draw_card()
	assert(no_card == null, "Attempting to draw from empty deck should return null")
	assert(deck.draw_pile.size() == 0, "Deck should remain 0 (no infinite recycling)")
	print("Finite deck check verified: draw_card returns null without recycling.")

	print("--- FINITE DECK TEST PASSED SUCCESSFULLY ---")
	quit(0)
