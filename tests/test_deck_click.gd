extends SceneTree

func _init() -> void:
	process_frame.connect(_run_test, CONNECT_ONE_SHOT)

func _run_test() -> void:
	print("--- BEGIN DECK CLICK TEST ---")
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	var game_node = game_scene.instantiate()
	game_node.use_game_cards_deck = false
	root.add_child(game_node)

	await process_frame
	await process_frame

	var deck: Deck = game_node.get_node("Deck") as Deck
	var hand: Hand = game_node.get_node("Hand") as Hand

	assert(deck != null, "Deck should exist")
	assert(hand != null, "Hand should exist")
	assert(hand.get_cards().size() == 0, "Hand starts with 0 cards")

	# Simulate mouse click input event on deck
	var click_event = InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	click_event.position = deck.global_position

	deck._on_input_event(null, click_event, 0)

	# Verify card was drawn as a result of click
	assert(hand.get_cards().size() == 1, "Clicking deck should draw 1 card into hand")
	var card = hand.get_cards()[0]
	assert(card is Card or card is GameCard, "Drawn node should be a Card or GameCard")
	print("Click successfully drew card: ", card)

	# Simulate hover
	deck._on_mouse_entered()
	assert(deck.is_hovered == true, "Deck is_hovered should be true")
	deck._on_mouse_exited()
	assert(deck.is_hovered == false, "Deck is_hovered should be false")

	print("--- DECK CLICK TEST PASSED ---")
	quit(0)
