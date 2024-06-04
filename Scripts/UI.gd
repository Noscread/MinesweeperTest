extends CanvasLayer

@onready var mine_count: Label = $PanelContainer/HBoxContainer/MineCountPanel/MineCount
@onready var game_state_button: TextureButton = $PanelContainer/HBoxContainer/GameStateButton
@onready var time_count: Label = $PanelContainer/HBoxContainer/TimeCountPanel/TimeCount

var game_lose_button_texture = preload("res://Assets/button_dead.png")
var game_win_button_texture = preload("res://Assets/button_cleared.png")

func set_mine_count(count: int) -> void:
	var count_str = str(count)
	if count_str.length() < 3:
		count_str = count_str.lpad(3, "0") # 必要时在该字符串的左侧添加若干character字符，使其长度至少为min_length。
	mine_count.text = count_str

func set_time_count(count: int) -> void:
	var count_str = str(count)
	if count_str.length() < 3:
		count_str = count_str.lpad(3, "0")
	time_count.text = count_str



func _on_game_state_button_pressed() -> void:
	get_tree().reload_current_scene()

func game_lose() -> void:
	game_state_button.texture_normal = game_lose_button_texture

func game_win() -> void:
	game_state_button.texture_normal = game_win_button_texture
