extends CanvasLayer

const BOARD_SIZE := 10
@onready var dict = preload("res://script/word_dict.gd").new()
@onready var board := $Board
var placed_this_turn: Array = []

func index_at(row: int, col: int) -> int:
	return row * BOARD_SIZE + col

func get_cell_text(row: int, col: int) -> String:
	var idx = index_at(row, col)
	var cell := board.get_child(idx)
	return cell.text.strip_edges().to_upper()

func is_cell_filled(row: int, col: int) -> bool:
	return get_cell_text(row, col) != ""

func collect_horizontal_words() -> Array:
	var results: Array = []
	for r in range(BOARD_SIZE):
		var row_string := ""
		var letter_indices := []

		for c in range(BOARD_SIZE):
			var ch := get_cell_text(r, c)
			row_string += (ch if ch != "" else " ")
			letter_indices.append(index_at(r, c))

		var clusters = row_string.split(" ", false)
		var start_index := 0

		for cluster in clusters:
			if cluster.length() == 0:
				start_index += 1
				continue

			var start_pos = row_string.find(cluster, start_index)
			if start_pos == -1:
				continue
			var cell_indices = []
			for i in range(cluster.length()):
				cell_indices.append(letter_indices[start_pos + i])

			for i in range(cluster.length()):
				for j in range(i + 1, cluster.length() + 1):
					var sub = cluster.substr(i, j - i)
					if sub.length() > 1 and dict.words.has(sub):
						var indices = cell_indices.slice(i, j)
						results.append({
							"word": sub,
							"cells": indices,
							"orientation": "H",
							"row": r
						})

			start_index += cluster.length() + 1
	return results

func collect_vertical_words() -> Array:
	var results: Array = []
	for c in range(BOARD_SIZE):
		var col_string := ""
		var letter_indices := []

		for r in range(BOARD_SIZE):
			var ch := get_cell_text(r, c)
			col_string += (ch if ch != "" else " ")
			letter_indices.append(index_at(r, c))

		var clusters = col_string.split(" ", false)
		var start_index := 0

		for cluster in clusters:
			if cluster.length() == 0:
				start_index += 1
				continue

			var start_pos = col_string.find(cluster, start_index)
			if start_pos == -1:
				continue
			var cell_indices = []
			for i in range(cluster.length()):
				cell_indices.append(letter_indices[start_pos + i])

			for i in range(cluster.length()):
				for j in range(i + 1, cluster.length() + 1):
					var sub = cluster.substr(i, j - i)
					if sub.length() > 1 and dict.words.has(sub):
						var indices = cell_indices.slice(i, j - i)
						results.append({
							"word": sub,
							"cells": indices,
							"orientation": "V",
							"col": c
						})

			start_index += cluster.length() + 1
	return results

func get_all_board_words() -> Array:
	var all := collect_horizontal_words()
	all += collect_vertical_words()
	return all

func get_words_from_placed_tiles() -> Array:
	if placed_this_turn.is_empty():
		return []
	var relevant: Array = []
	var all_words = get_all_board_words()
	for w in all_words:
		for idx in w.cells:
			if placed_this_turn.has(idx):
				relevant.append(w)
				break
	return relevant

func place_letter(cell_index: int, letter: String) -> void:
	var cell := board.get_child(cell_index)
	if cell.text == "":
		cell.text = letter.to_upper()
		if not placed_this_turn.has(cell_index):
			placed_this_turn.append(cell_index)
		submit_move()

func revert_placed_tiles() -> void:
	for idx in placed_this_turn:
		var cell := board.get_child(idx)
		cell.text = ""
	placed_this_turn.clear()

func submit_move() -> void:
	var formed := get_words_from_placed_tiles()
	if formed.is_empty():
		return
	
	var word_list = []
	for w in formed:
		word_list.append(w.word)

	print("Found: " + str(word_list))
	placed_this_turn.clear()
