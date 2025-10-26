extends CanvasLayer

@onready var anim: AnimationPlayer = $AnimationPlayer

var anim_finished: bool = false
var progress = []
var sceneName
var scene_load_status = 0

func _ready() -> void:
	sceneName = "res://scene/lobby.tscn"
	ResourceLoader.load_threaded_request(sceneName)
	anim.play("in")
	await anim.animation_finished
	anim.play("out")
	await anim.animation_finished
	anim_finished = true

func _physics_process(_delta: float) -> void:
	scene_load_status = ResourceLoader.load_threaded_get_status(sceneName,progress)
	if scene_load_status == ResourceLoader.THREAD_LOAD_LOADED:
		if anim_finished:
			var newScene = ResourceLoader.load_threaded_get(sceneName)
			get_tree().change_scene_to_packed(newScene)
			
