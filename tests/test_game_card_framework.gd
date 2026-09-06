extends SceneTree

func _init() -> void:
	process_frame.connect(_run_test, CONNECT_ONE_SHOT)

func _run_test() -> void:
	print("--- BEGIN GAME CARD FRAMEWORK TEST ---")
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	var game_node = game_scene.instantiate()
	game_node.auto_start_first_round = false
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

	# 1. Setup deck with custom GameCards (DrawCard)
	var draw_card_res: CardResource = load("res://resources/cards/draw_card.tres")
	assert(draw_card_res != null, "draw_card.tres exists")
	assert(draw_card_res.energy_cost == 1, "Draw card cost is 1")
	assert(draw_card_res.effects.size() == 1, "Draw card has 1 effect")
	assert(draw_card_res.effects[0] is DrawCardsEffect, "Effect is DrawCardsEffect")
	assert((draw_card_res.effects[0] as DrawCardsEffect).amount == 3, "Draw card draws 3 cards")

	var card_list: Array[CardResource] = []
	for i in range(12):
		card_list.append(draw_card_res)
	deck.custom_deck = card_list
	deck.generate_starter_deck()
	deck.initial_deck_size = deck.get_remaining_count()
	deck.update_stack_visual(false)

	assert(deck.get_remaining_count() == 12, "Deck has 12 cards")
	assert(energy_mgr.current_energy == 3, "Player starts with 3 energy")
	assert(hand.get_cards().size() == 0, "Hand starts empty when auto_start_first_round is false")

	# 2. Draw 1 card into hand
	var card1 = deck.draw_card()
	assert(card1 is GameCard, "Drawn card must be a GameCard")
	assert(card1.card_data == draw_card_res, "Card data should be draw_card_res")
	assert(hand.get_cards().size() == 1, "Hand has 1 card")
	assert(deck.get_remaining_count() == 11, "Deck has 11 remaining")

	# 3. Play card to table (costs 1 energy, triggers ability to draw 3 cards!)
	card1._pickup_card()
	card1.global_position = Vector2(0, -15)
	card1._drop_card()

	assert(card1.state == GameCard.State.ON_TABLE, "Card should now be on table")
	assert(table.played_cards.size() == 1, "Table has 1 played card")
	assert(energy_mgr.current_energy == 2, "Energy should drop from 3 to 2")
	# Ability triggered! Draw 3 cards was executed, so hand drew 3 cards!
	assert(hand.get_cards().size() == 3, "Hand should have 3 cards drawn by ability")
	assert(deck.get_remaining_count() == 8, "Deck should have 8 remaining after 3-card draw")
	print("Draw card played successfully: cost 1 energy and drew 3 cards!")

	# 4. Play another card (energy drops to 1, draws 3 cards)
	var card2 = hand.get_cards()[0] as GameCard
	card2._pickup_card()
	card2.global_position = Vector2(20, -15)
	card2._drop_card()

	assert(table.played_cards.size() == 2, "Table has 2 played cards")
	assert(energy_mgr.current_energy == 1, "Energy should drop from 2 to 1")
	# Hand had 3 cards, played 1, drew 3 => 5 cards
	assert(hand.get_cards().size() == 5, "Hand now has 5 cards")
	assert(deck.get_remaining_count() == 5, "Deck has 5 remaining")

	# 5. Play another card (energy drops to 0, draws 3 cards)
	var card3 = hand.get_cards()[0] as GameCard
	card3._pickup_card()
	card3.global_position = Vector2(40, -15)
	card3._drop_card()

	assert(energy_mgr.current_energy == 0, "Energy should drop from 1 to 0")
	assert(table.played_cards.size() == 3, "Table has 3 played cards")
	# Hand had 5 cards, played 1, drew 3 => 7 cards
	assert(hand.get_cards().size() == 7, "Hand now has 7 cards")
	assert(deck.get_remaining_count() == 2, "Deck has 2 remaining")

	# 6. Attempt to play when energy is 0 (unaffordable!)
	var card4 = hand.get_cards()[0] as GameCard
	card4._pickup_card()
	card4.global_position = Vector2(0, -15)
	card4._drop_card()

	assert(card4.state == GameCard.State.IN_HAND, "Card should be rejected and remain IN_HAND")
	assert(table.played_cards.size() == 3, "Table cards should still be 3")
	assert(energy_mgr.current_energy == 0, "Energy should remain 0")
	print("Unaffordable card correctly rejected when energy is 0!")

	# 7. Test resetting energy
	energy_mgr.reset_energy()
	assert(energy_mgr.current_energy == 3, "Energy reset to 3")
	print("Energy successfully reset to 3!")

	print("--- GAME CARD FRAMEWORK TEST PASSED SUCCESSFULLY ---")
	quit(0)
