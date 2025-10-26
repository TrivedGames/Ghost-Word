extends CanvasLayer

const BOARD_SIZE := 10
@onready var board := $Board
@onready var TileRack := $TileRack
@onready var player_name : Label = $player/status/player_name
@onready var opponent_name: Label = $opponent/opponent_status/opponent_name
@onready var opponent_score: Label = $opponent/opponent_status/score
@onready var dict = preload("res://script/word_dict.gd").new()
var placed_this_turn: Array = []
var my_words: Array = []
var placed_words: Array = []
var score: int = 0

var placed: bool = false
var updated: bool = false
var get_after_update: bool = false

func _ready() -> void:
	$timers/Timer.start()
	Supabase.connect("game_get", Callable(self, "_on_game_get"))
	Supabase.connect("game_updated", Callable(self, "_on_game_updated"))
	if GlobalGameData.game_row:
		player_name.text = GlobalGameData.local_player_name
		$uid/game_id.text = GlobalGameData.game_row["id"]
		if GlobalGameData.game_row["player2"] != "":
			opponent_name.text = GlobalGameData.game_row["player1"] if GlobalGameData.game_row["player1"] != GlobalGameData.local_player_name else GlobalGameData.game_row["player2"]
		else:
			opponent_name.text = "WAITING FOR OPPONENT..."

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	$player/status/time.text = in_min($timers/Timer.time_left)

func in_min(time: float) -> String:
	var minute = 0
	for i in range(1,11):
		if 60 * i > int(time):
			break
		minute += 1
	if int(time)%60 > 9:
		return str(minute) + ":" + str(int(time)%60)
	else:
		return str(minute) + ":0" + str(int(time)%60)

func _on_game_get(row: Dictionary) -> void:
	GlobalGameData.current_turn = int(row["current_turn"])
	GlobalGameData.game_row = row
	if GlobalGameData.game_row["player2"] != "":
		opponent_name.text = row["player1"] if GlobalGameData.local_player_name != row["player1"] else row["player2"]
	else:
		opponent_name.text = "WAITING FOR OPPONENT..."
	opponent_score.text = str(row["p1score"]) if GlobalGameData.local_player_name != GlobalGameData.game_row["player1"] else str(row["p2score"])
	var parsed = JSON.parse_string(row["board"])
	board.set_board_from_array(parsed)
	if updated:
		get_after_update = true
		print("getting after update")

@warning_ignore("unused_parameter")
func _on_game_updated(row: Dictionary) -> void:
	print("updated")
	updated = true

func index_at(row: int, col: int) -> int:
	return row * BOARD_SIZE + col

func get_cell_text(row: int, col: int) -> String:
	var idx = index_at(row, col)
	var cell := board.get_child(idx)
	return cell.get_child(0).text.strip_edges().to_upper()

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
						var indices = cell_indices.slice(i, j)
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
	if get_after_update or !placed:
		var cell := board.get_child(cell_index)
		if cell.get_child(0).text == "":
			cell.get_child(0).text = letter.to_upper()
			if not placed_this_turn.has(cell_index):
				placed_this_turn.append(cell_index)
		submit_move()

func revert_placed_tiles() -> void:
	for idx in placed_this_turn:
		var cell := board.get_child(idx)
		cell.get_child(0).text = ""
	placed_this_turn.clear()

func submit_move() -> void:
	var formed := get_words_from_placed_tiles()
	if !formed.is_empty():
		var valid_words := []
		for w in formed:
			if dict.words.has(w.word) and !placed_words.has(w.word):
				for inc in w.cells:
					board.get_child(inc).modulate = Color(6.5,0,0,1.0)
				valid_words.append(w.word)
		for w in valid_words:
			if placed_words.has(w):
				continue
			if !my_words.has(w):
				my_words.append(w)
			placed_words.append(w)
		if valid_words.size() <= 0:
			placed_this_turn.clear()
		score = ("".join(my_words)).length()
		$player/status/score.text = str(score)
	if GlobalGameData.game_row:
		var p1scr = score if GlobalGameData.local_player_name == GlobalGameData.game_row["player1"] else GlobalGameData.game_row["p1score"]
		var p2scr = score if GlobalGameData.local_player_name == GlobalGameData.game_row["player2"] else GlobalGameData.game_row["p2score"]
		var turn = 1 if GlobalGameData.local_player_name == GlobalGameData.game_row["player1"] else 0
		placed = true
		updated = false
		get_after_update = false
		board.send_board_array(p1scr,p2scr,turn)

func _on_copy_pressed() -> void:
	DisplayServer.clipboard_set($uid/game_id.text)
