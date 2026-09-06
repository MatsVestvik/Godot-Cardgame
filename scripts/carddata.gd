class_name CardData
extends RefCounted

var rank: Card.Rank
var suit: Card.Suit
var cardbase: Card.CardBase

func _init(p_rank: Card.Rank, p_suit: Card.Suit, p_cardbase: Card.CardBase = Card.CardBase.WHITE) -> void:
	rank = p_rank
	suit = p_suit
	cardbase = p_cardbase
