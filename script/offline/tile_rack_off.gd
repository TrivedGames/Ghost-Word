extends HBoxContainer

@onready var tile := preload("res://scene/tile_button.tscn")
var letters = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
var picked_letters:= []

func _ready():
	refresh_tiles(true)

func refresh_tiles(re_add:bool):
	for child in get_children():
		child.queue_free()
	if re_add:
		for I in range(4):
			picked_letters.append(letters.pick_random())
	for letter in picked_letters:
		var tile_inst = tile.instantiate()
		tile_inst.get_child(0).text = letter
		tile_inst.custom_minimum_size = Vector2(84, 40)
		tile_inst.connect("pressed", Callable(self, "_on_tile_pressed").bind(tile_inst.get_child(0).text))
		add_child(tile_inst)

func _on_tile_pressed(letter: String):
	get_parent().find_child("Board").selected_letter = letter
