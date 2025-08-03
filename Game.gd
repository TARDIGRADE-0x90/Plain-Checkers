extends Node
class_name Game

"""
	Next:
	> implement an option for forced jumps
	> implement option for looping border
	> implement a simple CPU that randomly chooses the steps and jumps open for it
"""

enum TURNS {WHITE, BLACK}

const BOARD_PATH: String = "res://Board.tscn"

const TOP_LEFT = Vector2(-1, -1)
const TOP_RIGHT = Vector2(1, -1)
const BOTTOM_LEFT = Vector2(-1, 1)
const BOTTOM_RIGHT = Vector2(1, 1)

@onready var board: Board = $Board
@onready var white_label = $Margin/WhiteLabel
@onready var black_label = $Margin/BlackLabel
@onready var restart_button = $Margin/Button

var current_turn: int = TURNS.WHITE
var active_piece: Piece
var multijump_active: bool = false

func _ready() -> void:
	restart_button.pressed.connect(refresh_board)
	current_turn = TURNS.WHITE
	initialize_board()
	handle_turn()

func initialize_board() -> void:
	for row in board.checker_tiles: #for each row in the tiles
		for i in range(row.size()): #and for each tile in that row
			row[i].tile_selected.connect(select_tile) #connect its signal
	
	for wp in board.white_pieces: 
		wp.chosen.connect(select_piece)
		wp.destroyed.connect(destroy_piece)
	
	for bp in board.black_pieces: 
		bp.chosen.connect(select_piece)
		bp.destroyed.connect(destroy_piece)

func refresh_board() -> void:
	board.queue_free() #Clear previous board
	var new_board = load(BOARD_PATH).instantiate()
	add_child(new_board)
	board = new_board #Reassign new board to the reference variable
	initialize_board()
	active_piece = null #Reset active piece for safety
	current_turn = TURNS.WHITE
	handle_turn()

func select_piece(piece: Piece) -> void:
	if multijump_active:
		return #don't select a new piece if multijump is active
	
	if active_piece: active_piece.cleared.emit() #clear previous piece if selecting a different one
	
	if piece.color_code == current_turn: #Disregard if the piece doesn't match the color of the current turn
		active_piece = piece
		active_piece.show_highlight()
	else:
		#some invalid sound effect
		pass

func select_tile(tile: CheckerTile) -> void: #Clear previous tile of the piece and set it open
	if active_piece: 
		var previous_tile: CheckerTile = board.checker_tiles[active_piece.current_rank][active_piece.rank_index]
		previous_tile.current_piece = null 
		previous_tile.is_open = true #Might be safer to replace with some null object, sentinel or whatever
		
		tile.current_piece = active_piece #Set new tile to the piece selected
		tile.is_open = false
		active_piece.position = tile.spot 
		
		active_piece.current_rank = tile.tile_rank #Update rank and rank index info for piece
		active_piece.rank_index = board.checker_tiles[active_piece.current_rank].find(tile)
		
		if tile in active_piece.valid_jumps: #Clear piece that's jumped over
			tile.jumpable_piece.destroy()
			active_piece.cleared.emit() #Clear previous steps and update with new tile
			clear_piece_queries(active_piece)
			check_piece_queries(active_piece)
			
			if !active_piece.valid_jumps.is_empty():
				return #Return if a multijump is available (and also stop other pieces from being selected somehow)
		
		#handle kinging
		match active_piece.color_code:
			TURNS.WHITE:
				if active_piece.current_rank == 0:
					active_piece.become_king()
			TURNS.BLACK:
				if active_piece.current_rank == board.BOARD_SIZE - 1:
					active_piece.become_king()
		
		#Replace with a signal that indicates the turn is finished 
		switch_turn() #End the turn

func switch_turn() -> void: #This just adds the turn by one, and keeps it between 0, 1, 0, 1, etc.
	active_piece.cleared.emit()
	
	match current_turn: #Clear valid steps/jumps since the turn for that color has ended
		TURNS.WHITE:
			if board.white_pieces.is_empty(): print("Black wins") #this conditional doesn't work, figure out something that does
			for wp in board.white_pieces:
				clear_piece_queries(wp)
		TURNS.BLACK:
			if board.black_pieces.is_empty(): print("White wins")
			for bp in board.black_pieces:
				clear_piece_queries(bp)
	
	current_turn = (current_turn + 1) % 2
	active_piece = null
	handle_turn()

func handle_turn() -> void:
	match current_turn:
		TURNS.WHITE:
			white_label.visible = true
			black_label.visible = false
		TURNS.BLACK:
			white_label.visible = false
			black_label.visible = true
	
	parse_valid_steps()

func parse_valid_steps() -> void:
	match current_turn: #Sets turn true for new 
		TURNS.WHITE:
			for piece in board.white_pieces:
				check_piece_queries(piece)
		TURNS.BLACK: 
			for piece in board.black_pieces: 
				check_piece_queries(piece)

func check_piece_queries(piece: Piece) -> void:
	if piece.kinged:
		check_top_queries(piece)
		check_bottom_queries(piece)
	else:
		match current_turn:
			TURNS.WHITE: check_top_queries(piece)
			TURNS.BLACK: check_bottom_queries(piece)

func clear_piece_queries(piece: Piece) -> void:
	piece.valid_steps.clear()
	piece.valid_jumps.clear()

func destroy_piece(piece: Piece) -> void:
	var piece_tile: CheckerTile = board.checker_tiles[piece.current_rank][piece.rank_index]
	piece_tile.is_open = true #Grab the corresponding tile under the piece and open it
	piece_tile.current_piece = null
	
	match piece.color_code: #Remove piece from piece array
		TURNS.WHITE: board.white_pieces.erase(piece)
		TURNS.BLACK: board.black_pieces.erase(piece)

func check_top_queries(piece: Piece) -> void:
	var top_left = query_step(piece, TOP_LEFT)
	var top_right = query_step(piece, TOP_RIGHT)
	var top_left_jump = query_jump(piece, TOP_LEFT, top_left)
	var top_right_jump = query_jump(piece, TOP_RIGHT, top_right)
	
	#The step queries may potentially return pieces; double if to confirm if tile meta is present
	if (top_left != null):
		if (top_left.has_meta(CheckerTile.META_IS_TILE)):
			piece.valid_steps.append(top_left)
	
	if (top_right != null):
		if (top_right.has_meta(CheckerTile.META_IS_TILE)):
			piece.valid_steps.append(top_right)
	
	#Jump queries just return null or tiles
	if (top_left_jump != null): piece.valid_jumps.append(top_left_jump)
	if (top_right_jump != null): piece.valid_jumps.append(top_right_jump)

func check_bottom_queries(piece: Piece) -> void:
	var bottom_left = query_step(piece, BOTTOM_LEFT)
	var bottom_right = query_step(piece, BOTTOM_RIGHT)
	var bottom_left_jump = query_jump(piece, BOTTOM_LEFT, bottom_left)
	var bottom_right_jump = query_jump(piece, BOTTOM_RIGHT, bottom_right)
	
	#The step queries may potentially return pieces; double if to confirm if tile meta is present
	if (bottom_left != null):
		if (bottom_left.has_meta(CheckerTile.META_IS_TILE)):
			piece.valid_steps.append(bottom_left)
	
	if (bottom_right != null):
		if (bottom_right.has_meta(CheckerTile.META_IS_TILE)):
			piece.valid_steps.append(bottom_right)
	
	#Jump queries just return null or tiles
	if (bottom_left_jump != null): piece.valid_jumps.append(bottom_left_jump)
	if (bottom_right_jump != null): piece.valid_jumps.append(bottom_right_jump)

#Querying:
#Evaluate if the new index exists in the CheckerTiles array and holds a CheckerTile that is currently open
#Returns a Variant - the CheckerTile if it's open, or the current piece if it's not empty
func query_step(piece: Piece, direction: Vector2) -> Variant:
	var rank_in_bound: bool = false #data to be defined based on the direction
	var index_in_bound: bool = false
	var rank_query: int 
	var index_query: int
	
	match direction: #determine bounds based on going up/down and left/right
		TOP_LEFT:
			rank_query = piece.current_rank - 1
			index_query = piece.rank_index - (piece.current_rank % 2) #rank is 0-based btw very important reminder
			rank_in_bound = (rank_query >= 0)
			index_in_bound = (index_query >= 0)
		
		TOP_RIGHT:
			rank_query = piece.current_rank - 1
			index_query = (piece.rank_index + 1) - (piece.current_rank % 2) 
			rank_in_bound = (rank_query >= 0)
			if rank_query < board.checker_tiles.size(): #Confirmation to prevent out of bounds error
				index_in_bound = (index_query < board.checker_tiles[rank_query].size())
		
		BOTTOM_LEFT:
			rank_query = piece.current_rank + 1
			index_query = piece.rank_index - (piece.current_rank % 2)
			rank_in_bound = (rank_query < board.BOARD_SIZE)
			index_in_bound = (index_query >= 0)
		
		BOTTOM_RIGHT:
			rank_query = piece.current_rank + 1
			index_query = piece.rank_index + 1 - (piece.current_rank % 2)
			rank_in_bound = (rank_query < board.BOARD_SIZE)
			if rank_query < board.checker_tiles.size():
				index_in_bound = (index_query < board.checker_tiles[rank_query].size())
	
	if rank_in_bound and index_in_bound:
		var tile_query = board.checker_tiles[rank_query][index_query]
		
		if (tile_query.is_open): #return the CheckerTile itself if open
			return (tile_query) 
		else: 
			return (tile_query.current_piece) #return the piece on the tile
	
	return null #Invalid query

#Jump querying:
#return the object from step queries, and if that object is in the enemy pieces array,
#determine if the new index is in the CheckerTiles array and if it holds an open CheckerTile
func query_jump(piece: Piece, direction: Vector2, step_query: Variant) -> Variant:
	var rank_in_bound: bool = false #data to be defined based on the direction
	var index_in_bound: bool = false
	var rank_query: int 
	var index_query: int
	
	match direction: #determine bounds based on going up/down and left/right
		TOP_LEFT:
			rank_query = piece.current_rank - 2
			index_query = piece.rank_index - 1
			rank_in_bound = (rank_query >= 0)
			index_in_bound = (index_query >= 0)
		
		TOP_RIGHT:
			rank_query = piece.current_rank - 2
			index_query = piece.rank_index + 1
			rank_in_bound = (rank_query >= 0)
			if rank_query < board.checker_tiles.size(): #Confirmation to prevent out of bounds error
				index_in_bound = (index_query < board.checker_tiles[rank_query].size())
		
		BOTTOM_LEFT:
			rank_query = piece.current_rank + 2
			index_query = piece.rank_index - 1
			rank_in_bound = (rank_query < board.BOARD_SIZE)
			index_in_bound = (index_query >= 0)
		
		BOTTOM_RIGHT:
			rank_query = piece.current_rank + 2
			index_query = piece.rank_index + 1
			rank_in_bound = (rank_query < board.BOARD_SIZE)
			if rank_query < board.checker_tiles.size():
				index_in_bound = (index_query < board.checker_tiles[rank_query].size())
	
	if (step_query == null) or \
		!(step_query.has_meta(piece.META_IS_PIECE)) or \
		(step_query.has_meta(piece.META_IS_PIECE) and \
		step_query.color_code == piece.color_code):
		return null #If no tile is found, an empty tile is found, or the jumpable tile is friendly, skip
	
	if rank_in_bound and index_in_bound:
		if (board.checker_tiles[rank_query][index_query].is_open): #If that specific tile is open,
			board.checker_tiles[rank_query][index_query].set_jumpable_piece(step_query) #Target the jumpable piece
			return (board.checker_tiles[rank_query][index_query]) #and return the CheckerTile itself
	
	return null
