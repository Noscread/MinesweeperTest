extends Node

@onready var mine_grid: MineGrid = $"../MineGrid"
@onready var ui: CanvasLayer = $"../UI"

@onready var game_timer: Timer = $GameTimer

var mine_count: int = 0
var time_count: int = 0


func _on_game_timer_timeout() -> void:
	time_count += 1
	ui.set_time_count(time_count)


func _on_mine_grid_update_flags(count: int) -> void:
	mine_count = count
	if mine_count == mine_grid.number_of_mines:
		mine_grid.check_win()
	ui.set_mine_count(mine_count)


func _on_mine_grid_lose() -> void:
	game_timer.stop()
	ui.game_lose()


func _on_mine_grid_win() -> void:
	game_timer.stop()
	ui.game_win()
