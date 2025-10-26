extends CanvasLayer

@onready var name_input := $input/VBoxContainer/name_txt
@onready var create_btn := $input/VBoxContainer/create
@onready var join_id_input := $input/VBoxContainer/HBoxContainer/id_txt
@onready var join_btn := $input/VBoxContainer/HBoxContainer/join
@onready var feedback := $input/VBoxContainer/feedbackLabel

var toggle_scrabble: bool = false
var progress = []
var sceneName
var scene_load_status = 0

func _ready() -> void:
	Supabase.connect("game_created", Callable(self, "_on_game_created"))
	Supabase.connect("game_error", Callable(self, "_on_game_error"))

func _physics_process(delta: float) -> void:
	if toggle_scrabble:
		scene_load_status = ResourceLoader.load_threaded_get_status(sceneName,progress)
		if scene_load_status == ResourceLoader.THREAD_LOAD_LOADED:
			var newScene = ResourceLoader.load_threaded_get(sceneName)
			get_tree().change_scene_to_packed(newScene)
	for btn:TextureButton in $btns.get_children():
		btn.scale = lerp(btn.scale, Vector2(1.2,1.2),3.0*delta) if btn.button_pressed else lerp(btn.scale, Vector2(1.0,1.0),3.0 * delta)
	
func _on_create_pressed():
	var player_name = name_input.text.strip_edges()
	if player_name == "":
		feedback.text = "Enter a name first"
		return
	Supabase.create_game(player_name)
	$AnimationPlayer.play("out")

func _on_join_pressed():
	var id = join_id_input.text.strip_edges()
	var player_name = name_input.text.strip_edges()
	if id == "" or player_name == "":
		feedback.text = "Enter game id and name"
		return
	Supabase.join_game(id, player_name)
	$AnimationPlayer.play("out")

func _on_game_created(row: Dictionary, join:bool = false) -> void:
	var id = row.id
	if join:
		GlobalGameData.local_player_name = row.player2
	else:
		GlobalGameData.local_player_name = row.player1
	GlobalGameData.game_row = row
	Supabase.subscribe_game(id)
	if $AnimationPlayer.is_playing():
		await $AnimationPlayer.animation_finished
		if scene_load_status == ResourceLoader.THREAD_LOAD_LOADED:
			var newScene = ResourceLoader.load_threaded_get(sceneName)
			get_tree().change_scene_to_packed(newScene)
	elif scene_load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var newScene = ResourceLoader.load_threaded_get(sceneName)
		get_tree().change_scene_to_packed(newScene)

func _on_game_error(msg: String):
	feedback.text = msg

func _on_homie_pressed() -> void:
	$input.show()

func _on_exit_input_pressed() -> void:
	$input.hide()

func _on_computer_pressed() -> void:
	sceneName = "res://scene/game_off.tscn"
	ResourceLoader.load_threaded_request(sceneName)
	$AnimationPlayer.play("out")
	await $AnimationPlayer.animation_finished
	toggle_scrabble = true
	
