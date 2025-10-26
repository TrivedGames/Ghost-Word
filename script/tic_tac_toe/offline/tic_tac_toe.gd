extends CanvasLayer

@onready var grid = $GridContainer
@onready var status_label = $Label

var board: Array = []
var current_player: String = "X"
var game_over_time: int = 0

func _ready() -> void:
	reset_board()

func reset_board() -> void:
	board = ["", "", "", "", "", "", "", "", ""]
	current_player = "X"
	status_label.text = str(game_over_time)

	for i in range(9):
		var btn := grid.get_child(i)
		btn.text = ""
		btn.disabled = false
		btn.pressed.connect(func(): on_cell_pressed(i))

func on_cell_pressed(index: int) -> void:
	if game_over_time >=3 or board[index] != "":
		return

	board[index] = current_player
	var btn := grid.get_child(index)
	btn.text = current_player
	btn.disabled = true

	if check_winner():
		status_label.text = "Winner: %s 🎉" % current_player
		game_over_time += 1
		disable_all_buttons()
		return

	if "" not in board:
		status_label.text = "It's a Draw! 🤝"
		return

	current_player = "O" if current_player == "X" else "X"
	status_label.text = "Turn: %s" % current_player

func disable_all_buttons() -> void:
	for i in range(9):
		grid.get_child(i).disabled = true

func check_winner() -> bool:
	var wins = [
		[0, 1, 2], [3, 4, 5], [6, 7, 8],
		[0, 3, 6], [1, 4, 7], [2, 5, 8],
		[0, 4, 8], [2, 4, 6]
	]

	for combo in wins:
		var a = board[combo[0]]
		var b = board[combo[1]]
		var c = board[combo[2]]
		if a != "" and a == b and b == c:
			return true

	return false
