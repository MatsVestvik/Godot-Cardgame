class_name Table
extends Area2D

signal card_played(card: Card)

@export var max_table_width: float = 200.0
@export var default_spacing: float = 26.0
@export var play_threshold_y: float = 15.0 # Global Y above which cards can be dropped to table
@export var show_play_zone_hint: bool = true

var played_cards: Array[Card] = []

func _ready() -> void:
	if show_play_zone_hint:
		queue_redraw()

func _draw() -> void:
	if show_play_zone_hint:
		# Draw subtle guide area for the play zone
		var zone_rect := Rect2(-110, -35, 220, 50)
		draw_rect(zone_rect, Color(1, 1, 1, 0.03), true)
		draw_rect(zone_rect, Color(1, 1, 1, 0.12), false, 1.0)

func can_accept_card(_card: Card, at_global_pos: Vector2) -> bool:
	# Accept if dropped above threshold or overlapping collision shape
	if at_global_pos.y <= play_threshold_y:
		return true
	return false

func play_card(card: Card) -> void:
	var old_parent = card.get_parent()
	
	if old_parent != self:
		if old_parent != null:
			card.reparent(self)
			if old_parent.has_method("update_hand_layout"):
				old_parent.update_hand_layout()
		else:
			add_child(card)

	if not played_cards.has(card):
		played_cards.append(card)

	card.state = Card.State.ON_TABLE
	card.is_dragging = false
	card.scale = Vector2(1.0, 1.0)

	update_table_layout()
	
	# Small punchy bounce animation when landing on the table
	var tween := create_tween()
	tween.tween_property(card, "scale", Vector2(1.15, 1.15), 0.08)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.1)

	card_played.emit(card)

func update_table_layout() -> void:
	var total_cards := played_cards.size()
	if total_cards == 0:
		return

	var spacing := default_spacing
	if total_cards > 1:
		var available_space := max_table_width / float(total_cards - 1)
		spacing = min(default_spacing, available_space)

	var total_span := (total_cards - 1) * spacing
	var start_x := -total_span / 2.0

	for i in range(total_cards):
		var card := played_cards[i]
		var target_pos := Vector2(start_x + (i * spacing), 0.0)
		card.z_index = i
		card.base_z_index = i
		card.resting_position = global_position + target_pos

		var tween := create_tween()
		tween.tween_property(card, "position", target_pos, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func clear_table() -> Array[Card]:
	var cleared: Array[Card] = played_cards.duplicate()
	for card in played_cards:
		remove_child(card)
	played_cards.clear()
	return cleared
