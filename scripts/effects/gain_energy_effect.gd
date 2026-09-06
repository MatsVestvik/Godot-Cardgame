class_name GainEnergyEffect
extends CardEffect

@export var amount: int = 1

func apply(context: Dictionary) -> void:
	if context.has("energy_manager") and context.energy_manager != null:
		context.energy_manager.gain(amount)

func get_description() -> String:
	return "Gain %d Energy." % amount
