class_name CardResource
extends Resource

@export var id: String = ""
@export var card_name: String = ""
@export_range(0, 9) var energy_cost: int = 1
@export var art_texture: Texture2D
@export_multiline var description: String = ""
@export var effects: Array[CardEffect] = []

func execute(context: Dictionary) -> void:
	for effect in effects:
		if effect != null:
			effect.apply(context)
