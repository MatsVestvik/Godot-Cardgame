class_name EnergyManager
extends Node

signal energy_changed(current: int, max_energy: int)

@export var max_energy: int = 3
var current_energy: int = 3

func _ready() -> void:
	current_energy = max_energy
	energy_changed.emit(current_energy, max_energy)

func can_afford(cost: int) -> bool:
	return current_energy >= cost

func spend(cost: int) -> bool:
	if can_afford(cost):
		current_energy -= cost
		energy_changed.emit(current_energy, max_energy)
		return true
	return false

func gain(amount: int) -> void:
	current_energy = min(current_energy + amount, max_energy)
	energy_changed.emit(current_energy, max_energy)

func reset_energy() -> void:
	current_energy = max_energy
	energy_changed.emit(current_energy, max_energy)
