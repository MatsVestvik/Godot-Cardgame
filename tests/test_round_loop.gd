extends SceneTree

func _init() -> void:
	process_frame.connect(_run_test, CONNECT_ONE_SHOT)

func _run_test() -> void:
	print("--- BEGIN ROUND LOOP & PERSISTENT ENERGY TEST ---")
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	var game_node: Game = game_scene.instantiate() as Game
	root.add_child(game_node)

	await process_frame
	await process_frame

	var deck: Deck = game_node.get_node("Deck") as Deck
	var hand: Hand = game_node.get_node("Hand") as Hand
	var table: Table = game_node.get_node("Table") as Table
	var energy_mgr: EnergyManager = game_node.get_node("EnergyManager") as EnergyManager

	assert(deck != null, "Deck exists")
	assert(hand != null, "Hand exists")
	assert(table != null, "Table exists")
	assert(energy_mgr != null, "EnergyManager exists")

	# 1. Verify 60-card starter deck and round 1 hand start
	assert(energy_mgr.energy_cap == 9, "Energy cap must be 9")
	assert(energy_mgr.max_energy == 9, "Max energy must be 9")
	assert(energy_mgr.current_energy == 3, "Starting energy is 3")
	assert(game_node.current_round == 1, "Game starts at round 1")
	assert(hand.get_cards().size() == 5, "Hand starts with 5 cards dealt at beginning of round")
	assert(deck.get_remaining_count() == 55, "Deck has 55 cards remaining (60 - 5 dealt)")
	print("Verified: 60-card deck initialized, 5 cards dealt to hand, energy starts at 3/9.")

	# 2. Verify Draw card draws 3 cards
	var draw_res: CardResource = load("res://resources/cards/draw_card.tres")
	assert(draw_res.energy_cost == 1, "Draw card cost is 1")
	assert(draw_res.effects[0] is DrawCardsEffect, "Effect is DrawCardsEffect")
	assert((draw_res.effects[0] as DrawCardsEffect).amount == 3, "DrawCardsEffect draws 3 cards")

	# Spawn a guaranteed draw card in hand for deterministic test
	var draw_card_instance: GameCard = load("res://scenes/gameCard.tscn").instantiate()
	draw_card_instance.setup_card(draw_res)
	hand.add_card(draw_card_instance)

	var hand_count_before: int = hand.get_cards().size()
	var deck_count_before: int = deck.get_remaining_count()

	# Play the draw card
	draw_card_instance._pickup_card()
	draw_card_instance.global_position = Vector2(0, -15)
	draw_card_instance._drop_card()

	assert(draw_card_instance.state == GameCard.State.ON_TABLE, "Draw card played to table")
	assert(energy_mgr.current_energy == 2, "Energy decreased by 1 (cost 1)")
	# Hand played 1 card (-1) and drew 3 cards (+3) => net +2
	assert(hand.get_cards().size() == hand_count_before + 2, "Hand drew 3 cards from Draw ability")
	assert(deck.get_remaining_count() == deck_count_before - 3, "Deck decreased by 3 cards")
	print("Verified: Draw card costs 1 energy and draws 3 cards successfully.")

	# 3. Test Energy card and cap 9
	var energy_res: CardResource = load("res://resources/cards/energy_card.tres")
	var energy_card_instance: GameCard = load("res://scenes/gameCard.tscn").instantiate()
	energy_card_instance.setup_card(energy_res)
	hand.add_card(energy_card_instance)

	energy_card_instance._pickup_card()
	energy_card_instance.global_position = Vector2(20, -15)
	energy_card_instance._drop_card()

	assert(energy_card_instance.state == GameCard.State.ON_TABLE, "Energy card played to table")
	assert(energy_mgr.current_energy == 3, "Energy increased by 1 at cost 0 (2 -> 3)")
	assert(table.played_cards.size() == 2, "Table has 2 cards on the board")
	print("Verified: Energy card played, increased energy by 1 at cost 0.")

	# Stack energy to cap of 9
	energy_mgr.gain(10)
	assert(energy_mgr.current_energy == 9, "Energy capped at 9")

	# 4. Test Ending Turn: Clears the board & preserves persistent energy
	var discard_count_before: int = deck.discard_pile.size()
	game_node._on_end_turn_pressed()

	await process_frame
	await process_frame

	assert(table.played_cards.is_empty(), "Table board was cleared on end turn")
	assert(deck.discard_pile.size() == discard_count_before + 2, "Cleared cards moved to discard pile")
	assert(energy_mgr.current_energy == 9, "Energy remained persistent (9) across rounds without resetting!")
	assert(game_node.current_round == 2, "Round advanced to 2")
	print("Verified: End turn clears table to discard pile and persists energy across rounds.")

	# 5. Test Hand refill to 5 cards at round start
	# Clear hand down to 2 cards to test refill
	var cards_in_hand := hand.get_cards()
	while cards_in_hand.size() > 2:
		var c = cards_in_hand.pop_back()
		hand.remove_card(c)
		c.queue_free()

	assert(hand.get_cards().size() == 2, "Hand now has 2 cards")

	# End turn to start round 3
	game_node._on_end_turn_pressed()

	await process_frame
	await process_frame

	assert(hand.get_cards().size() == 5, "Hand was refilled to 5 cards at the start of round 3")
	assert(energy_mgr.current_energy == 9, "Energy still persistent at 9")
	assert(game_node.current_round == 3, "Round advanced to 3")
	print("Verified: Hand refilled up to 5 cards at beginning of new round.")

	print("--- ROUND LOOP & PERSISTENT ENERGY TEST PASSED SUCCESSFULLY ---")
	quit(0)
