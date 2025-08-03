extends Area2D
class_name CheckerTile

signal piece_chosen
signal piece_cleared
signal tile_selected(tile: CheckerTile)

const META_IS_TILE: String = "IsTile"
const WAVE_TIME: float = 0.2

@onready var sprite = $Sprite
@onready var clickable = $ClickableComponent
@onready var highlight_timer = $HighlightTimer
@onready var debug_label = $Label

var current_piece: Piece
var jumpable_piece: Piece
var tile_rank: int = 0
var is_open: bool 
var spot: Vector2

var selectable_now: bool = false

func _init() -> void:
	set_meta(META_IS_TILE, true)

func _ready() -> void:
	mouse_entered.connect(clickable.detect_hover)
	mouse_exited.connect(clickable.clear_hover)
	clickable.clicked.connect(select)
	
	piece_chosen.connect(highlight_tile)
	piece_cleared.connect(clear_highlight)
	
	highlight_timer.wait_time = WAVE_TIME

func _process(_delta) -> void:
	pass
	#put animation effects here later

func init(new_spot: Vector2, rank: int, open: bool = true, piece: Piece = null) -> void:
	spot = new_spot
	tile_rank = rank
	is_open = open
	current_piece = piece

func set_spot(new_spot: Vector2) -> void:
	spot = new_spot

func set_rank(new_rank: int) -> void:
	tile_rank = new_rank

func set_open(open: bool) -> void:
	is_open = open

func set_piece(piece: Piece) -> void:
	current_piece = piece

func set_jumpable_piece(piece: Piece) -> void:
	jumpable_piece = piece

func set_debug_label(text: String) -> void:
	debug_label.set_text(text)

func highlight_tile() -> void:
	selectable_now = true
	sprite.visible = true

func clear_highlight() -> void:
	selectable_now = false
	sprite.visible = false

func select() -> void:
	if selectable_now:
		selectable_now = false
		tile_selected.emit(self)
	else:
		pass
