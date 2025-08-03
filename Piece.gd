extends Area2D
class_name Piece

signal chosen(this_piece: Piece)
signal cleared
signal destroyed(this_piece: Piece)

enum COLORS {WHITE, BLACK}

const META_IS_PIECE: String = "IsPiece"
const WHITE_PATH: String = "res://Assets/PieceAlt.png"
const BLACK_PATH: String = "res://Assets/Piece.png"
const WHITE_KING_PATH: String = "res://Assets/KingPieceAlt.png"
const BLACK_KING_PATH: String = "res://Assets/KingPiece.png"

@onready var sprite = $Sprite
@onready var highlight = $Highlight
@onready var label = $Label
@onready var clickable = $ClickableComponent

var valid_steps: Array[CheckerTile]
var valid_jumps: Array[CheckerTile]

var current_rank: int = 0
var rank_index: int = 0
var color_code: int = 0
var kinged: bool = false

func _init() -> void:
	set_meta(META_IS_PIECE, true)

func _ready() -> void:
	mouse_entered.connect(clickable.detect_hover)
	mouse_exited.connect(clickable.clear_hover)
	clickable.clicked.connect(select)
	cleared.connect(deselect)

func init(color_type: int, new_rank: int, new_rank_index: int) -> void:
	set_color(color_type)
	set_rank(new_rank)
	set_rank_index(new_rank_index)

func set_debug_label(text: String) -> void:
	label.text = text

func set_color(color_type: int) -> void:
	color_code = color_type
	match color_code:
		COLORS.WHITE: sprite.set_texture(load(WHITE_PATH))
		COLORS.BLACK: sprite.set_texture(load(BLACK_PATH))

func set_rank(new_rank: int) -> void:
	current_rank = new_rank

func set_rank_index(new_rank_index: int) -> void:
	rank_index = new_rank_index

func show_highlight() -> void:
	highlight.visible = true

func clear_highlight() -> void:
	highlight.visible = false

func select() -> void:
	chosen.emit(self)
	
	if valid_steps:
		for step in valid_steps:
			step.piece_chosen.emit()
	
	if valid_jumps:
		for jump in valid_jumps:
			jump.piece_chosen.emit()

func deselect() -> void:
	clear_highlight()
	
	if valid_steps:
		for step in valid_steps:
			step.piece_cleared.emit()
	
	if valid_jumps:
		for jump in valid_jumps:
			jump.piece_cleared.emit()

func become_king() -> void:
	kinged = true
	match color_code:
		COLORS.WHITE: sprite.set_texture(load(WHITE_KING_PATH))
		COLORS.BLACK: sprite.set_texture(load(BLACK_KING_PATH))

func destroy() -> void:
	destroyed.emit(self)
	queue_free()
