extends SceneTree

func _init() -> void:
	process_frame.connect(_run_test, CONNECT_ONE_SHOT)

func _run_test() -> void:
	print("--- BEGIN PLAY CARD TEST ---")
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	var game_node = game_scene.instantiate()
	root.add_child(game_node)

	await process_frame
	await process_frame

	var deck: Deck = game_node.get_node("Deck") as Deck
	var hand: Hand = game_node.get_node("Hand") as Hand
	var table: Table = game_node.get_node("Table") as Table

	assert(deck != null, "Deck should exist")
	assert(hand != null, "Hand should exist")
	assert(table != null, "Table should exist")

	# 1. Draw 3 cards into Hand
	var c1 = deck.draw_card()
	var c2 = deck.draw_card()
	var c3 = deck.draw_card()

	assert(hand.get_cards().size() == 3, "Hand should have 3 cards")
	assert(table.played_cards.size() == 0, "Table should have 0 cards")

	# 2. Test playing card c1 to the Table (drop at Y = -15, which is < play_threshold_y 15)
	c1._pickup_card()
	assert(c1.is_dragging == true, "c1 should be dragging")
	c1.global_position = Vector2(0, -15) # moved onto the table
	c1._drop_card()

	assert(c1.is_dragging == false, "c1 should stop dragging after drop")
	assert(c1.state == Card.State.ON_TABLE, "c1 state should be ON_TABLE")
	assert(c1.get_parent() == table, "c1 should now be child of Table")
	assert(table.played_cards.size() == 1, "Table should have 1 played card")
	assert(hand.get_cards().size() == 2, "Hand should now have 2 cards")
	print("Successfully played card 1 to table!")

	# 3. Test playing card c2 to the Table as well
	c2._pickup_card()
	c2.global_position = Vector2(20, -10)
	c2._drop_card()

	assert(table.played_cards.size() == 2, "Table should have 2 played cards")
	assert(hand.get_cards().size() == 1, "Hand should have 1 card left")
	print("Successfully played card 2 to table! Table cards dynamically re-centered.")

	# 4. Test invalid drop below threshold (drop c3 at Y = 35)
	c3._pickup_card()
	c3.global_position = Vector2(0, 35) # stayed near hand
	c3._drop_card()

	assert(c3.state == Card.State.IN_HAND, "c3 should remain IN_HAND")
	assert(c3.get_parent() == hand, "c3 should remain child of Hand")
	assert(table.played_cards.size() == 2, "Table count should remain 2")
	assert(hand.get_cards().size() == 1, "Hand count should remain 1")
	print("Invalid drop correctly returned card 3 to hand slot!")

	print("--- PLAY CARD TEST PASSED SUCCESSFULLY ---")
	quit(0)
