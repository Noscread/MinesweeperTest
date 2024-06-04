extends TileMap

class_name MineGrid

## 图块坐标
const CELLS = { 
	"1": Vector2i(0, 0),
	"2": Vector2i(1, 0),
	"3": Vector2i(2, 0),
	"4": Vector2i(3, 0),
	"5": Vector2i(4, 0),
	"6": Vector2i(0, 1),
	"7": Vector2i(1, 1),
	"8": Vector2i(2, 1),
	"CLEAR": Vector2i(3, 1),
	"MINE_RED": Vector2i(4, 1),
	"FLAG": Vector2i(0, 2),
	"MINE": Vector2i(1, 2),
	"DEFAULT": Vector2i(2, 2)
}
## 默认tileset图块id
const TILE_SET_ID = 0
## 隐藏层
const HIDE_LAYER = 0
## 显示层
const SHOW_LAYER = 1
## 地图行数
@export var rows: int = 8
## 地图列数
@export var columns: int = 8
## 总地雷数
@export var number_of_mines: int = 10
## 已放置地雷的坐标数组
var cells_with_mines: Array[Vector2i] = []
## 已递归检查过的坐标数组
var cells_checked: Array[Vector2i] = []
## 已放置的旗子坐标数组
var cells_flaged: Array[Vector2i] = []
## 游戏是否结束
var is_game_finished: bool = false
## 是否是首次点击
var is_first_click: bool = true

## 获胜的信号
signal win
## 失败的信号
signal lose
## 旗子数量更新
signal update_flags(count: int)

func _ready() -> void:
	init_all_layer()

# 监听玩家输入
func _input(event: InputEvent) -> void:	
	# if event.is_action_pressed("test"): # 测试
	# 	print(cells_flaged == cells_with_mines) # == 条件 大小相等 内容顺序相等 即全等
	# 	print(cells_with_mines)
	# 	print(cells_flaged)

	if is_game_finished:
		return


	if event is InputEventMouseButton && event.pressed: # 是鼠标按键被按下或松开事件 and 按下了鼠标
		var click_cell_coord = local_to_map(get_local_mouse_position()) # 获取鼠标点击的地图坐标
		# 防止首次点击到雷，第一次点击后才开始放置地雷
		if is_first_click:
			place_mines(click_cell_coord)
			is_first_click = false

		var tile_show_data = get_cell_tile_data(SHOW_LAYER, click_cell_coord) # 获取当前坐标格子的tile数据
		var tile_hide_data = get_cell_tile_data(HIDE_LAYER, click_cell_coord)

		if tile_hide_data == null: # 空白处
			return
		elif tile_show_data != null: # 没打开的格子
			if event.button_index == 1: #鼠标左键点击
				left_clicked_closed(click_cell_coord)
			elif event.button_index == 2: #鼠标右键点击
				place_flag(click_cell_coord)
		elif tile_show_data == null && event.button_index == 1: # 已经打开的格子上按下左键
			left_clicked_opened(click_cell_coord)


## 判断是否获胜
func check_win() -> void:
	cells_flaged.sort()
	cells_with_mines.sort()
	if cells_flaged == cells_with_mines:
		is_game_finished = true
		win.emit()

## 游戏失败，显示所有炸弹
func game_lose(cell_coord: Vector2i) -> void:
	is_game_finished = true
	set_tile_cell(cell_coord, "MINE_RED", HIDE_LAYER)
	set_layer_enabled(SHOW_LAYER, false)
	lose.emit()


## 鼠标左键点击事件，打开格子
func left_clicked_closed(cell_coord: Vector2i) -> void:	
	if get_coord_key(cell_coord, SHOW_LAYER) == "FLAG":
		return

	if cells_with_mines.any(func (cell): return cell == cell_coord): # 如果点击的是放置地雷的坐标
		click_mine(cell_coord)
		return

	check_cell(cell_coord) # 递归检查周围格子的情况

## 点击地雷
func click_mine(cell_coord: Vector2i) -> void:
	# print("你点到了地雷")
	game_lose(cell_coord)

## 获取图块坐标的key
func get_coord_key(cell_coord: Vector2i, layer: int) -> String:
	var atlas_coord = get_cell_atlas_coords(layer, cell_coord) # 获取当前坐标格子的图块坐标
	for key in CELLS.keys():
		# print(key)
		if CELLS[key] == atlas_coord:
			return key
	return ""

## 递归检查单个坐标格子的情况
func check_cell(cell_coord: Vector2i) -> void:
	if cells_checked.has(cell_coord):
		return

	var is_flag = get_coord_key(cell_coord, SHOW_LAYER) == "FLAG"

	var coord_hide_key = get_coord_key(cell_coord, HIDE_LAYER)
	match coord_hide_key:
		"1", "2", "3", "4", "5", "6", "7", "8":
			if is_flag:
				place_flag(cell_coord)
			erase_cell(SHOW_LAYER, cell_coord)
			cells_checked.append(cell_coord)
		"CLEAR":
			if is_flag:
				place_flag(cell_coord)
			erase_cell(SHOW_LAYER, cell_coord)
			cells_checked.append(cell_coord)
			# 递归检查周围格子的情况
			for i in [-1, 0 ,1]:
				for j in [-1, 0, 1]:
					check_cell(cell_coord + Vector2i(i, j))
		_:
			return
	


# 鼠标右键点击事件，放置旗子
func place_flag(cell_coord: Vector2i) -> void:
	var is_flag = get_coord_key(cell_coord, SHOW_LAYER) == "FLAG"
	if is_flag:
		set_tile_cell(cell_coord, "DEFAULT", SHOW_LAYER)
		cells_flaged.erase(cell_coord)
		update_flags.emit(cells_flaged.size())
	else:
		set_tile_cell(cell_coord, "FLAG", SHOW_LAYER)
		cells_flaged.append((cell_coord))
		update_flags.emit(cells_flaged.size())

## 鼠标左键点击事件，检查快速打开周围格子
func left_clicked_opened(cell_coord: Vector2i) -> void:
	# print(cell_coord)
	var surround_mine_number = get_surround_mine_number(cell_coord)
	if surround_mine_number == 0:
		return

	var surround_cells: Array[Vector2i] = []
	# var surround_default_cells: Array[Vector2i] = []
	var surround_flags_number: int = 0
	for i in [-1, 0, 1]:
		for j in [-1, 0, 1]:
			var cell = cell_coord + Vector2i(i, j)
			if get_cell_tile_data(SHOW_LAYER, cell) != null:
				surround_cells.append(cell)
			# print(get_coord_key(cell, SHOW_LAYER))
			if get_coord_key(cell, SHOW_LAYER) == "FLAG":
				surround_flags_number += 1
	
	# 触发条件：1、雷的数量 == 周围格子数 2、旗子数 >= 雷数 分开讨论
	#   正确处理 1情况绝对正确 2情况看实际正确的数量是否和雷数相等
	#   错误处理
	# print(surround_mine_number)
	# print(surround_flags_number)
	if surround_mine_number == surround_cells.size(): # 雷的数量 == 周围格子数
		# print("雷数==周围格子数")
		for cell in surround_cells: # 放置旗子
			var is_flag = get_coord_key(cell, SHOW_LAYER) == "FLAG"
			var is_mine = get_coord_key(cell, HIDE_LAYER) == "MINE"
			if !is_flag && is_mine:
				set_tile_cell(cell, "FLAG", SHOW_LAYER)
				cells_flaged.append((cell))
				update_flags.emit(cells_flaged.size())
	elif surround_flags_number >= surround_mine_number: # 旗子数 >= 雷数
		var right_count = 0
		for cell in surround_cells:
			var is_flag = get_coord_key(cell, SHOW_LAYER) == "FLAG"
			var is_mine = get_coord_key(cell, HIDE_LAYER) == "MINE"
			if is_flag && is_mine:
				right_count += 1
				
		if right_count == surround_mine_number: # 处理正确情况
			# print("正确")
			for cell in surround_cells:
				var is_flag = get_coord_key(cell, SHOW_LAYER) == "FLAG"
				var is_mine = get_coord_key(cell, HIDE_LAYER) == "MINE"
				if !is_flag && !is_mine:
					left_clicked_closed(cell)
		else:
			# print("错误")
			for cell in surround_cells:
				var is_flag = get_coord_key(cell, SHOW_LAYER) == "FLAG"
				var is_mine = get_coord_key(cell, HIDE_LAYER) == "MINE"
				if !is_flag && is_mine:
					left_clicked_closed(cell)
				elif is_flag && !is_mine:
					set_tile_cell(cell, "DEFAULT", SHOW_LAYER)
					cells_flaged.erase(cell)
					update_flags.emit(cells_flaged.size())
					left_clicked_closed(cell)

		pass
			


## 初始化显示层和隐藏层
func init_all_layer() -> void:
	clear_layer(HIDE_LAYER)
	clear_layer(SHOW_LAYER)
	for i in rows:
		#var str := "" # 拼接字符串打印结果
		for j in columns: # 范围[0-n/2,n-1-n/2] i区间[0,n-1]
			var cell_coord = Vector2i(i - rows / 2, j - columns / 2)
			set_tile_cell(cell_coord, "DEFAULT", SHOW_LAYER)
			set_tile_cell(cell_coord, "CLEAR", HIDE_LAYER)
			#str += str(cell_coord) +" "
		#print(str)

## 设置隐藏层的地雷，完善隐藏层的图块
func place_mines(click_cell_coord: Vector2i) -> void:
	cells_with_mines.clear()
	number_of_mines = number_of_mines if number_of_mines < rows * columns else rows * columns
	for i in number_of_mines: # 范围[0-n/2,n-1-n/2]
		var cell_coord = Vector2i(randi_range(0 - rows / 2, rows - 1 - rows / 2),
			randi_range(0 - columns / 2, columns - 1 - columns / 2))
		while cells_with_mines.has(cell_coord) || cell_coord == click_cell_coord: # 去重
			cell_coord = Vector2i(randi_range(0 - rows / 2, rows - 1 - rows / 2),
			randi_range(0 - columns / 2, columns - 1 - columns / 2))
		cells_with_mines.append(cell_coord)
	#print(cells_with_mines)
	
	for cell_coord in cells_with_mines:
		# erase_cell(DEFAULT_LAYER, cell_coord) # 删除原位置的图块，可以不写，会覆盖
		set_tile_cell(cell_coord, "MINE", HIDE_LAYER)

	# 完善隐藏层的图块
	for i in rows:
		for j in columns:
			var cell_coord = Vector2i(i - rows / 2, j - columns / 2)
			if !cells_with_mines.has(cell_coord):
				var mine_number = get_surround_mine_number(cell_coord)
				if mine_number > 0:
					set_tile_cell(cell_coord, str(mine_number), HIDE_LAYER)

## 获取周围的地雷数量
func get_surround_mine_number(cell_coord: Vector2i) -> int:
	var mine_count = 0
	# var surrounding_cells = get_surrounding_cells(cell_coord) # get_surrounding_cells 只获取上下左右四个方向的坐标
	var surrounding_cells: Array[Vector2i] = []
	for i in [-1, 0 ,1]:
		for j in [-1, 0, 1]:
			surrounding_cells.append(cell_coord + Vector2i(i, j))
	for cell in surrounding_cells:
		var hide_atlas_coord = get_cell_atlas_coords(HIDE_LAYER, cell)
		if hide_atlas_coord == CELLS.MINE:
			mine_count += 1
	return mine_count

## 设置地图块内容
func  set_tile_cell(cell_coord: Vector2i, cell_type: String, layer:int):
	set_cell(layer, cell_coord, TILE_SET_ID, CELLS[cell_type])
