extends SceneTree

func _init() -> void:
	process_frame.connect(_run_test, CONNECT_ONE_SHOT)

func _run_test() -> void:
	print("--- BEGIN ENERGY CARD TEST ---")
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	var game_node = game_scene.instantiate()
	root.add_child(game_node)

	await process_frame
	await process_frame

	var deck: Deck = game_node.get_node("Deck") as Deck
	var hand: Hand = game_node.get_node("Hand") as Hand
	var table: Table = game_node.get_node("Table") as Table
	var energy_mgr: EnergyManager = game_node.get_node("EnergyManager") as EnergyManager

	# 1. Verify Energy card resource
	var energy_res: CardResource = load("res://resources/cards/energy_card.tres")
	assert(energy_res != null, "energy_card.tres exists")
	assert(energy_res.energy_cost == 0, "Energy card must cost 0 energy")
	assert(energy_res.card_name == "Energy", "Card name should be Energy")
	assert(energy_res.effects.size() == 1, "Energy card has 1 effect")
	assert(energy_res.effects[0] is GainEnergyEffect, "Effect is GainEnergyEffect")
	assert(energy_res.effects[0].amount == 1, "GainEnergyEffect amount should be 1")
	print("Energy card resource verified: cost 0, +1 energy.")

	# 2. Setup deck with Energy cards
	var deck_cards: Array[CardResource] = []
	for i in range(12):
		deck_cards.append(energy_res)
	deck.custom_deck = deck_cards
	deck.generate_starter_deck()
	deck.initial_deck_size = deck.get_remaining_count()
	deck.update_stack_visual(false)

	assert(energy_mgr.current_energy == 3, "Starts at 3 energy")
	assert(energy_mgr.energy_cap == 9, "Energy cap is 9")

	# 3. Draw and play 1 Energy card
	var c1 = deck.draw_card() as GameCard
	assert(c1 != null, "Drew GameCard")
	assert(c1.card_data == energy_res, "Card data is Energy card")

	c1._pickup_card()
	c1.global_position = Vector2(0, -15)
	c1._drop_card()

	assert(c1.state == GameCard.State.ON_TABLE, "Card played to table")
	assert(energy_mgr.current_energy == 4, "Energy should increase from 3 to 4")
	print("Played Energy card: energy successfully increased to 4!")

	# 4. Play cards up to energy cap (9)
	# Current is 4. Play 5 more to reach 9.
	for i in range(5):
		var c = deck.draw_card() as GameCard
		c._pickup_card()
		c.global_position = Vector2(0, -15)
		c._drop_card()

	assert(energy_mgr.current_energy == 9, "Energy should have reached the cap of 9")
	print("Reached energy cap of 9!")

	# 5. Play another Energy card while at cap 9
	var c_extra = deck.draw_card() as GameCard
	c_extra._pickup_card()
	c_extra.global_position = Vector2(0, -15)
	c_extra._drop_card()

	assert(energy_mgr.current_energy == 9, "Energy must not exceed the cap of 9")
	print("Energy cap enforced: remaining at 9 despite extra energy card.")

	# 6. Reset energy (End Turn)
	energy_mgr.reset_energy()
	assert(energy_mgr.current_energy == 3, "Energy reset back to base 3 on end turn")
	print("Energy reset back to 3 verified.")

	print("--- ENERGY CARD TEST PASSED SUCCESSFULLY ---")
	quit(0)
