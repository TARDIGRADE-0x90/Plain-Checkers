extends Node2D
class_name Board

const PIECE_PATH: String = "res://Piece.tscn"
const CHECKER_TILE_PATH: String = "res://CheckerTile.tscn"

const MAX_PIECES: int = 12
const BOARD_SIZE: int = 8
const TILE_STEP: int = 64
const OFFSET: int = 32

var checker_tiles: Array[Array] = [ [], [], [], [], [], [], [], [] ]
#8 ROWS of 4 COLUMNS; this is a hard set initialization for now

var black_pieces: Array[Piece]
var white_pieces: Array[Piece]

func _ready() -> void:
	initialize_tiles()
	generate_black_pieces()
	generate_white_pieces()

func initialize_tiles() -> void:
	var temp_tiles: Array[CheckerTile] 
	var full_size := int(BOARD_SIZE * BOARD_SIZE * 0.5) #only half of the board is usable
	var x_step: int = TILE_STEP
	var y_step: int = 0
	var rank: int = 0
	
	for i in range(full_size): #Traverses such that it hops a tile after each placement
		var location = Vector2((x_step % (BOARD_SIZE * TILE_STEP)) + OFFSET, y_step + OFFSET)
		var new_tile: CheckerTile = create_tile(location, rank)
		temp_tiles.append(new_tile)
		
		x_step += (TILE_STEP * 2)
		if ( (i+1) % int(BOARD_SIZE * 0.5) == 0 ): #push down for new row
			checker_tiles[rank].assign(temp_tiles) #Add to double array and refresh before the start of each row
			temp_tiles.clear()
			rank += 1
			
			y_step += TILE_STEP
			if ( (i+1) % BOARD_SIZE != 0 ): x_step -= TILE_STEP
			else: x_step += TILE_STEP #shift it to the left every row, or keep its x_start every other row

func generate_black_pieces() -> void:
	var x_step: int = TILE_STEP
	var y_step: int = 0
	var rank: int = 0
	#I hate the fact that this is copy and pasted 3 times and I don't know how to make it better
	for i in range(MAX_PIECES): #Traverses such that it hops a tile after each placement
		var tile_spawn = Vector2(Vector2((x_step % (BOARD_SIZE * TILE_STEP)) + OFFSET, y_step + OFFSET))
		var rank_index: int = (i % int(BOARD_SIZE * 0.5))
		var new_piece: Piece = create_piece(tile_spawn, Piece.COLORS.BLACK, rank, rank_index)
		
		checker_tiles[rank][rank_index].set_open(false)
		checker_tiles[rank][rank_index].set_piece(new_piece)
		black_pieces.append(new_piece)
		
		x_step += (TILE_STEP * 2)
		if ( (i+1) % int(BOARD_SIZE * 0.5) == 0 ): #push down for new row
			rank += 1
			y_step += TILE_STEP
			if ( (i+1) % BOARD_SIZE != 0 ): x_step -= TILE_STEP
			else: x_step += TILE_STEP #shift it to the left every row, or keep its x_start every other row

func generate_white_pieces() -> void:
	var x_step: int = 0
	var y_step: int = (BOARD_SIZE - int(MAX_PIECES * 0.25)) * TILE_STEP #white starts at a certain position lower
	var rank: int = (BOARD_SIZE - int(MAX_PIECES * 0.25))
	#THE GENERATION HERE IS SLIGHTLY DIFFERENT; IT WORKS NOW SO DO NOT FUCKING TOUCH IT
	for i in range(MAX_PIECES): #Traverses such that it hops a tile after each placement
		var tile_spawn = Vector2(Vector2((x_step % (BOARD_SIZE * TILE_STEP)) + OFFSET, y_step + OFFSET))
		var rank_index: int = (i % int(BOARD_SIZE * 0.5))
		var new_piece: Piece = create_piece(tile_spawn, Piece.COLORS.WHITE, rank, rank_index)
		
		checker_tiles[rank][rank_index].set_open(false)
		checker_tiles[rank][rank_index].set_piece(new_piece)
		white_pieces.append(new_piece)
		
		x_step += (TILE_STEP * 2) #Difference is here
		if ( (i+1) % int(BOARD_SIZE * 0.5) == 0 ): #push down for new row
			rank += 1
			y_step += TILE_STEP
			if ( (i+1) % BOARD_SIZE != 0 ): x_step = TILE_STEP
			else: x_step = 0 #shift it to the left every row, or keep its x_start every other row

func create_piece(at_tile: Vector2, color_type: int, rank: int, rank_index: int) -> Piece: 
	var new_piece: Piece = load(PIECE_PATH).instantiate()
	add_child(new_piece)
	new_piece.init(color_type, rank, rank_index)
	new_piece.position = at_tile #position is used rather than global to keep it relative to the board's position
	new_piece.set_debug_label(str(new_piece.rank_index))
	
	return new_piece #return for convenience in adding to white/black pieces

func create_tile(location: Vector2, rank: int) -> CheckerTile:
	var new_tile: CheckerTile = load(CHECKER_TILE_PATH).instantiate()
	add_child(new_tile)
	new_tile.init(location, rank)
	new_tile.position = location
	
	return new_tile
