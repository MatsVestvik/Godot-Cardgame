extends Area2D

@onready var energy_cost: Sprite2D = $"energy cost"
@onready var art: Sprite2D = $art

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_setArt(Vector2i(1,1))
	_setEnergyCost(Vector2i(9,0))

func _setArt(coords: Vector2i) -> void:
	art.frame_coords = coords
	
func _setEnergyCost(coords: Vector2i) -> void:
	energy_cost.frame_coords = coords
