extends GridContainer

@onready var cell := preload("res://scene/button.tscn")
var selected_letter = ""

func _ready():
	for i in range(100):
		var cell_int = cell.instantiate()
		cell_int.get_child(0).text = ""
		cell_int.custom_minimum_size = Vector2(62.5, 55.8)
		cell_int.connect("pressed", Callable(self, "_on_cell_pressed").bind(i))
		add_child(cell_int)

func set_board_from_array(board:Array):
	var current_letter: Array = []
	for btn in get_children():
		current_letter.append(btn.get_child(0).text)
	if ("".join(board)).length() > ("".join(current_letter)).length():
		for btn in range(board.size()):
			get_child(btn).get_child(0).text = board[btn]

func _on_cell_pressed(index: int):
	if get_child(index).get_child(0).text == "":
		get_parent().place_letter(index, selected_letter)
		get_parent().find_child("TileRack").picked_letters.erase(selected_letter)
		var count = (get_parent().find_child("TileRack").picked_letters).size()
		get_parent().find_child("Rack_back").get_child(count - 1).hide()
		get_parent().find_child("TileRack").refresh_tiles(false)
		selected_letter = ""
		if get_parent().find_child("TileRack").picked_letters.is_empty():
			for rack in get_parent().find_child("Rack_back").get_children():
				rack.show()
			get_parent().find_child("TileRack").refresh_tiles(true)
