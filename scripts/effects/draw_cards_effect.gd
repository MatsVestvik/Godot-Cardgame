class_name DrawCardsEffect
extends CardEffect

@export var amount: int = 3

func apply(context: Dictionary) -> void:
	if context.has("deck") and context.deck != null:
		context.deck.draw_hand(amount)

func get_description() -> String:
	if amount == 1:
		return "Draw 1 card."
	return "Draw %d cards." % amount
