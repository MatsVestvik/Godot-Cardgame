class_name GameCard
extends Area2D

signal card_played(card: GameCard)
signal drag_started(card: GameCard)
signal drag_ended(card: GameCard)

const CARD_WIDTH: float = 46.0
const CARD_HEIGHT: float = 64.0

enum State { IN_HAND, ON_TABLE }

@export var card_data: CardResource

@onready var card_sprite: Sprite2D = $card
@onready var art_sprite: Sprite2D = $art
@onready var energy_cost_sprite: Sprite2D = $"energy cost"

var state: State = State.IN_HAND
var is_hovered: bool = false
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var resting_position: Vector2 = Vector2.ZERO
var base_z_index: int = 0

func _ready() -> void:
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	if card_data != null:
		setup_card(card_data)

func setup_card(resource: CardResource) -> void:
	card_data = resource

	if art_sprite == null:
		art_sprite = get_node_or_null("art")
	if energy_cost_sprite == null:
		energy_cost_sprite = get_node_or_null("energy cost")

	if art_sprite and card_data.art_texture:
		art_sprite.texture = card_data.art_texture

	if energy_cost_sprite and energy_cost_sprite.texture:
		energy_cost_sprite.texture = energy_cost_sprite.texture.duplicate()
		var atlas := energy_cost_sprite.texture as AtlasTexture
		if atlas:
			var digit := clampi(card_data.energy_cost, 0, 9)
			atlas.region.position = Vector2(digit * 9, 0)

func _process(_delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position() - drag_offset

func _input(event: InputEvent) -> void:
	if is_dragging and event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_drop_card()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and state == State.IN_HAND:
			_pickup_card()

func _pickup_card() -> void:
	is_dragging = true
	resting_position = global_position
	drag_offset = get_global_mouse_position() - global_position
	z_index = 100
	drag_started.emit(self)

func _drop_card() -> void:
	is_dragging = false
	drag_ended.emit(self)

	var table: Table = _find_table()
	var energy_mgr: EnergyManager = _find_energy_manager()

	if table != null and state == State.IN_HAND and table.can_accept_card(self, global_position):
		var cost := card_data.energy_cost if card_data != null else 0
		if energy_mgr != null and not energy_mgr.can_afford(cost):
			_play_unaffordable_animation()
			_return_to_resting_position()
			return

		if energy_mgr != null:
			energy_mgr.spend(cost)

		table.play_card(self)
		card_played.emit(self)
		_trigger_ability(table)
		return

	_return_to_resting_position()

func _return_to_resting_position() -> void:
	z_index = base_z_index
	var tween := create_tween()
	tween.tween_property(self, "global_position", resting_position, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _play_unaffordable_animation() -> void:
	var orig_pos := resting_position
	var tween := create_tween()
	var orig_modulate := modulate
	modulate = Color(1.0, 0.4, 0.4, 1.0)
	tween.tween_property(self, "modulate", orig_modulate, 0.25)

func _trigger_ability(table: Table) -> void:
	if card_data != null:
		var context := {
			"card": self,
			"table": table,
			"deck": _find_deck(),
			"hand": _find_hand(),
			"energy_manager": _find_energy_manager(),
			"game": get_tree().current_scene
		}
		card_data.execute(context)

func _find_table() -> Table:
	var tree := get_tree()
	if tree != null:
		var found = tree.root.find_child("Table", true, false)
		if found is Table:
			return found
	return null

func _find_energy_manager() -> EnergyManager:
	var tree := get_tree()
	if tree != null:
		var found = tree.root.find_child("EnergyManager", true, false)
		if found is EnergyManager:
			return found
	return null

func _find_deck() -> Deck:
	var tree := get_tree()
	if tree != null:
		var found = tree.root.find_child("Deck", true, false)
		if found is Deck:
			return found
	return null

func _find_hand() -> Hand:
	var tree := get_tree()
	if tree != null:
		var found = tree.root.find_child("Hand", true, false)
		if found is Hand:
			return found
	return null

func _on_mouse_entered() -> void:
	is_hovered = true
	if not is_dragging:
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.08)

func _on_mouse_exited() -> void:
	is_hovered = false
	if not is_dragging:
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.08)
