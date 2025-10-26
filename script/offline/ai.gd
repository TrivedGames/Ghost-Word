extends Node

@onready var board = $"../Board"
var board_size := 10
var board_cells: Array = []
var letters: Array= ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
var ai_letters : Array = []

func _ready():
	for i in range(4):
		ai_letters.append(letters.pick_random())
	for ch in board.get_children():
		board_cells.append(ch.get_child(0).text)
	ai_place_letter()

func ai_place_letter():
	for i in range(100):
		board_cells[i] = board.get_child(i).get_child(0).text
	
	if ai_letters.is_empty():
		for i in range(4):
			ai_letters.append(letters.pick_random())
	
	var empty_pos: Array = []
	var word_positions = _find_existing_words()
	var target_pos = -1
	var chosen_letter = ai_letters.pick_random()
	
	if word_positions.size() > 0:
		target_pos = _find_extension_spot(word_positions)
		if target_pos == -1:
			target_pos = _find_random_adjacent()
	else:
		for i in range(100):
			if board.get_child(i).get_child(0).text.is_empty():
				empty_pos.append(i)
			else:
				print(board.get_child(i).get_child(0).text)
		if empty_pos.is_empty():
			print("Empty now")
			for idx in range(board_cells.size()):
				if board_cells[idx] == "":
					target_pos = idx
		else:
			print(empty_pos)
			target_pos = empty_pos.pick_random()
			print("picking random")
	if target_pos != -1:
		board_cells[target_pos] = chosen_letter
		print("AI placed '%s' at index %d" % [chosen_letter, target_pos])
		board.get_child(target_pos).get_child(0).text = chosen_letter
		ai_letters.erase(chosen_letter)
	else:
		print("No valid position found for AI.")

	_print_board()
	_end_turn()

func _find_existing_words() -> Array:
	var word_positions = []
	for r in range(board_size):
		var current_word = []
		for c in range(board_size):
			var i = r * board_size + c
			if board_cells[i] != "":
				current_word.append(i)
			elif current_word.size() > 1:
				word_positions.append(current_word.duplicate())
				current_word.clear()
			else:
				current_word.clear()

		if current_word.size() > 1:
			word_positions.append(current_word.duplicate())

	return word_positions

func _find_extension_spot(words: Array) -> int:
	for word in words:
		var left = word[0] - 1
		var right = word[-1] + 1

		if left >= 0 and left / board_size == word[0] / board_size and board_cells[left] == "":
			return left

		if right < board_cells.size() and right / board_size == word[-1] / board_size and board_cells[right] == "":
			return right

	return -1

func _find_random_adjacent() -> int:
	var candidates = []
	for i in range(board_cells.size()):
		if board_cells[i] == "" and _is_adjacent_to_letter(i):
			candidates.append(i)

	if candidates.size() > 0:
		return candidates[randi() % candidates.size()]
	return -1

func _is_adjacent_to_letter(index: int) -> bool:
	var row = index / board_size
	var col = index % board_size
	var dirs = [
		Vector2(1, 0), Vector2(-1, 0),
		Vector2(0, 1), Vector2(0, -1)
	]

	for d in dirs:
		var r = row + int(d.y)
		var c = col + int(d.x)
		if r >= 0 and r < board_size and c >= 0 and c < board_size:
			var n = r * board_size + c
			if board_cells[n] != "":
				return true
	return false

func _print_board():
	for r in range(board_size):
		var row_str = ""
		for c in range(board_size):
			var i = r * board_size + c
			row_str += board_cells[i] if board_cells[i] != "" else "."

func _end_turn():
	print("AI turn ended.\n")

func _on_button_pressed() -> void:
	ai_place_letter()
