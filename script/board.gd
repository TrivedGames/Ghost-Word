extends GridContainer

@onready var cell := preload("res://scene/button.tscn")
@onready var wordslist: WordDictionary = preload("res://dictionary.tres")
var selected_letter = ""

func _ready():
	for i in range(100):
		var cell_int = cell.instantiate()
		cell_int.get_child(0).text = ""
		cell_int.custom_minimum_size = Vector2(62.5, 55.8)
		cell_int.connect("pressed", Callable(self, "_on_cell_pressed").bind(i))
		add_child(cell_int)

func send_board_array(p1sc: int,p2sc:int,turn:int) -> void:
	var arra: Array = []
	for btn in get_children():
		arra.append(btn.get_child(0).text)
	Supabase.update_game(GlobalGameData.game_row["id"], arra, p1sc,p2sc,turn)

func set_board_from_array(board:Array):
	var current_letter: Array = []
	for btn in get_children():
		current_letter.append(btn.get_child(0).text)
	if ("".join(board)).length() > ("".join(current_letter)).length():
		for btn in range(board.size()):
			get_child(btn).get_child(0).text = board[btn]
		for i in range(100):
			if !get_child(i).get_child(0).text.is_empty():
				if !get_parent().placed_this_turn.has(i):
					get_parent().placed_this_turn.append(i)
		var formed = get_parent().get_words_from_placed_tiles()
		if formed.is_empty():
			return
		var valid_words := []
		for w in formed:
			if wordslist.words.has(w.word) and !get_parent().placed_words.has(w.word):
				valid_words.append(w.word)
		
		for w in valid_words:
			if get_parent().placed_words.has(w):
				continue
			get_parent().placed_words.append(w)

func _on_cell_pressed(index: int):
	if selected_letter and (GlobalGameData.local_player_name == GlobalGameData.game_row["player1"] and GlobalGameData.current_turn == 0) or (GlobalGameData.local_player_name == GlobalGameData.game_row["player2"] and GlobalGameData.current_turn == 1):
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
