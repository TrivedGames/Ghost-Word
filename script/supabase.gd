extends Node

const SUPABASE_URL : String = "https://nhcokxuuvwtaxwlfgepa.supabase.co"
const SUPABASE_KEY : String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5oY29reHV1dnd0YXh3bGZnZXBhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk1NTMxOTcsImV4cCI6MjA3NTEyOTE5N30.Q-NI5f7-Hle5pw1o8fqSr8ObHtHsQwtt4gYlcTXP7zM"

const GAMES_TABLE_ENDPOINT := SUPABASE_URL + "/rest/v1/games"

var _default_headers := [
	"apikey: %s" % SUPABASE_KEY,
	"Authorization: Bearer %s" % SUPABASE_KEY,
	"Content-Type: application/json",
	"Prefer: return=representation"
	]

signal game_created(game_row : Dictionary)
signal game_updated(game_row : Dictionary)
signal game_get(game_row : Dictionary)
signal game_error(error: String)

@onready var _poll_timer := Timer.new()
var _current_subscription_game_id : String = ""

var http : HTTPRequest
var request_type:String = ""

var update_http: HTTPRequest

func _ready() -> void:
	http = HTTPRequest.new()
	update_http = HTTPRequest.new()
	add_child(update_http)
	add_child(http)
	http.request_completed.connect(_on_request_completed)
	update_http.request_completed.connect(_on_update_completed)
	add_child(_poll_timer)
	_poll_timer.wait_time = 2.0
	_poll_timer.one_shot = false
	_poll_timer.connect("timeout", Callable(self, "_on_poll_timeout"))

func create_game(player : String):
	var body = {
		"board": [],
		"player1": player,
		"player2": "",
		"current_turn": 0,
		"p1score": 0,
		"p2score": 0
	}
	request_type = "create"
	http.request(GAMES_TABLE_ENDPOINT, _default_headers,HTTPClient.METHOD_POST, JSON.stringify(body))

func join_game(id,player_name) -> void:
	var body = {
		"player2": player_name
	}
	request_type = "join"
	http.request(GAMES_TABLE_ENDPOINT + "?id=eq." + id, _default_headers,HTTPClient.METHOD_PATCH, JSON.stringify(body))

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var resp_text = body.get_string_from_utf8()
	var data = {}
	
	if result == HTTPRequest.RESULT_SUCCESS:
		if response_code in [200, 201]:
			if resp_text != "":
				var parsed = JSON.parse_string(resp_text)
				data = parsed[0]
				match request_type:
					"create":
						emit_signal("game_created",data)
					"join":
						emit_signal("game_created",data, true)
					"get":
						emit_signal("game_get",data)
	else:
		emit_signal("game_error",str(result))

func _on_update_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var resp_text = body.get_string_from_utf8()
	var data = {}
	
	if result == HTTPRequest.RESULT_SUCCESS:
		if response_code in [200, 201]:
			if resp_text != "":
				var parsed = JSON.parse_string(resp_text)
				data = parsed[0]
				emit_signal("game_updated",data)
	else:
		emit_signal("game_error",str(result))

func get_game(game_id : String) -> void:
	request_type = "get"
	http.request(GAMES_TABLE_ENDPOINT + "?id=eq." + game_id,_default_headers,HTTPClient.METHOD_GET)

func update_game(game_id : String, board : Array, p1score : int, p2score: int,current_turn : int) -> void:
	var url = "%s?id=eq.%s" % [GAMES_TABLE_ENDPOINT, game_id]
	var payload = {
		"board": board,
		"p1score": p1score,
		"p2score": p2score,
		"current_turn": current_turn
	}
	request_type = "update"
	update_http.request(url, _default_headers, HTTPClient.METHOD_PATCH, JSON.stringify(payload))

func subscribe_game(game_id : String) -> void:
	_current_subscription_game_id = game_id
	_poll_timer.start()

func _on_poll_timeout():
	if _current_subscription_game_id == "":
		return
	get_game(_current_subscription_game_id)

func unsubscribe():
	_current_subscription_game_id = ""
	_poll_timer.stop()
