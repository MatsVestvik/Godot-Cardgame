class_name Card
extends Area2D

# Dimensions
const CARD_WIDTH: float = 23.0
const CARD_HEIGHT: float = 32.0
const RANK_WIDTH: float = 7.0
const RANK_HEIGHT: float = 5.0
const SUIT_WIDTH: float = 7.0
const SUIT_HEIGHT: float = 7.0

# Enums
enum Suit { CLUBS = 3, SPADES = 1, HEARTS = 0, DIAMONDS = 2 }
enum Rank { TWO = 0, THREE = 1, FOUR = 2, FIVE = 3, SIX = 4, SEVEN = 5, EIGHT = 6, NINE = 7, TEN = 8, JACK = 9, QUEEN = 10, KING = 11, ACE = 12 }
enum CardBase { WHITE = 0, GREEN = 1, RED = 2, BLUE = 3 }

@onready var base_sprite: Sprite2D = $CardBase
@onready var rank_sprite: Sprite2D = $Rank
@onready var suit_sprite: Sprite2D = $Suit

# Interaction state variables
var is_hovered: bool = false
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var resting_position: Vector2 = Vector2.ZERO
var base_z_index: int = 0

func _ready() -> void:
	_make_textures_unique()
	# Connect built-in Area2D signals via code
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _process(_delta: float) -> void:
	if is_dragging:
		# Follow global mouse coordinates minus grab point
		global_position = get_global_mouse_position() - drag_offset

func _input(event: InputEvent) -> void:
	# Release the card when mouse button is released anywhere
	if is_dragging and event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_drop_card()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pickup_card()

func _pickup_card() -> void:
	is_dragging = true
	resting_position = global_position
	drag_offset = get_global_mouse_position() - global_position
	z_index = 100  # Ensure card renders on top while dragging

func _drop_card() -> void:
	is_dragging = false
	z_index = base_z_index
	
	# Smoothly slide the card back into its resting slot
	var tween := create_tween()
	tween.tween_property(self, "global_position", resting_position, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_mouse_entered() -> void:
	is_hovered = true
	if not is_dragging:
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.08)

func _on_mouse_exited() -> void:
	is_hovered = false
	if not is_dragging:
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.08)

func _make_textures_unique() -> void:
	if base_sprite == null:
		base_sprite = get_node_or_null("CardBase")
	if rank_sprite == null:
		rank_sprite = get_node_or_null("Rank")
	if suit_sprite == null:
		suit_sprite = get_node_or_null("Suit")

	if base_sprite and base_sprite.texture:
		base_sprite.texture = base_sprite.texture.duplicate()
	if rank_sprite and rank_sprite.texture:
		rank_sprite.texture = rank_sprite.texture.duplicate()
	if suit_sprite and suit_sprite.texture:
		suit_sprite.texture = suit_sprite.texture.duplicate()

func setup_card(rank: Rank, suit: Suit, cardbase: CardBase) -> void:
	if base_sprite == null:
		base_sprite = get_node_or_null("CardBase")
	if rank_sprite == null:
		rank_sprite = get_node_or_null("Rank")
	if suit_sprite == null:
		suit_sprite = get_node_or_null("Suit")

	_make_textures_unique()

	var base_atlas := base_sprite.texture as AtlasTexture
	if base_atlas:
		base_atlas.region.position = Vector2(cardbase * CARD_WIDTH, 0)

	var rank_atlas := rank_sprite.texture as AtlasTexture
	if rank_atlas:
		rank_atlas.region.position = Vector2(rank * RANK_WIDTH, 0)

	var suit_atlas := suit_sprite.texture as AtlasTexture
	if suit_atlas:
		suit_atlas.region.position = Vector2(suit * SUIT_WIDTH, 0)
