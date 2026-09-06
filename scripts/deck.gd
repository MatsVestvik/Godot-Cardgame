class_name Deck
extends Area2D

signal card_drawn(card: Node2D, card_info: Variant)

const CARD_SCENE: PackedScene = preload("res://scenes/card.tscn")
const STANDARD_CARD_SCENE: PackedScene = preload("res://scenes/card.tscn")
const GAME_CARD_SCENE: PackedScene = preload("res://scenes/gameCard.tscn")
const CARD_WIDTH: float = 23.0
const CARD_HEIGHT: float = 32.0

@export var target_hand: Hand
@export var can_draw: bool = true
@export var auto_recycle: bool = false
@export var max_stack_height: int = 7
@export var show_card_counter: bool = true
@export var custom_deck: Array[CardResource] = []

@onready var top_card_sprite: Sprite2D = $TopCard
@onready var shadow_sprite: Sprite2D = $Shadow
@onready var stack_layers_container: Node2D = $StackLayers
@onready var count_label: Label = get_node_or_null("CountLabel")

var draw_pile: Array[CardData] = []
var custom_draw_pile: Array[CardResource] = []
var discard_pile: Array[Variant] = []
var initial_deck_size: int = 52
var current_stack_height: int = 7
var stack_sprites: Array[Sprite2D] = []
var is_hovered: bool = false

func _ready() -> void:
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	generate_starter_deck()
	initial_deck_size = get_remaining_count()
	shuffle_draw_pile()
	_setup_stack_layers()
	update_stack_visual(false)

	if target_hand == null:
		_find_target_hand()

func get_remaining_count() -> int:
	return custom_draw_pile.size() + draw_pile.size()

func _draw() -> void:
	if get_remaining_count() == 0:
		var rect := Rect2(-CARD_WIDTH / 2.0, -CARD_HEIGHT / 2.0, CARD_WIDTH, CARD_HEIGHT)
		draw_rect(rect, Color(1, 1, 1, 0.04), true)
		draw_rect(rect, Color(1, 1, 1, 0.25), false, 1.0)

func _setup_stack_layers() -> void:
	if stack_layers_container == null:
		return
	for child in stack_layers_container.get_children():
		child.queue_free()
	stack_sprites.clear()

	var tex: Texture2D = top_card_sprite.texture if top_card_sprite else null
	for i in range(1, max_stack_height + 1):
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.position = Vector2(0, -i)
		var shade: float = lerpf(0.72, 0.94, float(i) / float(max_stack_height))
		spr.modulate = Color(shade, shade, shade, 1.0)
		stack_layers_container.add_child(spr)
		stack_sprites.append(spr)

func update_stack_visual(animate: bool = true) -> void:
	var remaining := get_remaining_count()

	if count_label != null:
		count_label.visible = show_card_counter
		count_label.text = str(remaining)

	queue_redraw()

	if remaining == 0:
		current_stack_height = 0
		if top_card_sprite: top_card_sprite.visible = false
		if shadow_sprite: shadow_sprite.visible = false
		if stack_layers_container: stack_layers_container.visible = false
		return

	if top_card_sprite: top_card_sprite.visible = true
	if shadow_sprite: shadow_sprite.visible = true
	if stack_layers_container: stack_layers_container.visible = true

	var target_height: int = max(1, int(ceil((float(remaining) / float(initial_deck_size)) * float(max_stack_height))))
	current_stack_height = target_height

	for i in range(stack_sprites.size()):
		stack_sprites[i].visible = (i + 1) < target_height

	var target_pos := Vector2(0, -target_height)
	if top_card_sprite:
		if animate:
			var tween := create_tween()
			tween.tween_property(top_card_sprite, "position", target_pos, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			top_card_sprite.position = target_pos

func _find_target_hand() -> void:
	var tree := get_tree()
	if tree != null:
		var found = tree.root.find_child("Hand", true, false)
		if found is Hand:
			target_hand = found

func _on_mouse_entered() -> void:
	is_hovered = true
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.06, 1.06), 0.08)

func _on_mouse_exited() -> void:
	is_hovered = false
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.08)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not can_draw:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_play_click_animation()
		draw_card()

func _play_click_animation() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.94, 0.94), 0.05)
	tween.tween_property(self, "scale", Vector2(1.06, 1.06) if is_hovered else Vector2(1.0, 1.0), 0.08)

func _play_empty_deck_animation() -> void:
	var orig_pos := position
	var tween := create_tween()
	tween.tween_property(self, "position", orig_pos + Vector2(-3, 0), 0.04)
	tween.tween_property(self, "position", orig_pos + Vector2(3, 0), 0.04)
	tween.tween_property(self, "position", orig_pos + Vector2(-2, 0), 0.04)
	tween.tween_property(self, "position", orig_pos, 0.04)

func generate_starter_deck() -> void:
	draw_pile.clear()
	custom_draw_pile.clear()
	discard_pile.clear()

	if not custom_deck.is_empty():
		for res in custom_deck:
			custom_draw_pile.append(res)
	else:
		for suit in Card.Suit.values():
			for rank in Card.Rank.values():
				draw_pile.append(CardData.new(rank, suit, Card.CardBase.WHITE))

func shuffle_draw_pile() -> void:
	draw_pile.shuffle()
	custom_draw_pile.shuffle()

func recycle_discard_into_draw() -> void:
	for item in discard_pile:
		if item is CardResource:
			custom_draw_pile.append(item)
		elif item is CardData:
			draw_pile.append(item)
	discard_pile.clear()
	shuffle_draw_pile()
	update_stack_visual(true)

func draw_card() -> Node2D:
	if target_hand == null:
		_find_target_hand()
		if target_hand == null:
			push_warning("Deck: No target Hand assigned or found in scene!")
			return null

	if get_remaining_count() == 0:
		if auto_recycle and not discard_pile.is_empty():
			recycle_discard_into_draw()
		else:
			print("No cards left to draw!")
			_play_empty_deck_animation()
			return null

	var spawn_pos: Vector2 = top_card_sprite.global_position if (top_card_sprite and top_card_sprite.visible) else global_position

	if not custom_draw_pile.is_empty():
		var next_res: CardResource = custom_draw_pile.pop_back()
		var new_card: GameCard = GAME_CARD_SCENE.instantiate()
		new_card.global_position = spawn_pos
		new_card.setup_card(next_res)
		target_hand.add_card(new_card)
		update_stack_visual(true)
		card_drawn.emit(new_card, next_res)
		return new_card
	else:
		var next_card_data: CardData = draw_pile.pop_back()
		var new_card: Card = STANDARD_CARD_SCENE.instantiate()
		new_card.global_position = spawn_pos
		new_card.setup_card(next_card_data.rank, next_card_data.suit, next_card_data.cardbase)
		target_hand.add_card(new_card)
		update_stack_visual(true)
		card_drawn.emit(new_card, next_card_data)
		return new_card

func draw_hand(amount: int) -> void:
	for i in range(amount):
		draw_card()
