extends Node2D

const CARD_SCENE_PATH = "res://Scenes/Card.tscn"
const CARD_DRAW_SPEED = 0.5
#var player_deck = ["E1", "E2", "E3", "E4", "E5", "E6", "E7", "E8", "E9", "E10"
				#, "M1", "M2", "M3", "M4", "M5", "M6", "M7", "M8", "M9", "M10"
				#, "T1", "T2", "T3", "T4", "T5", "T6", "T7", "T8", "T9", "T10"
				#, "P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8", "P9", "P10"]
var player_deck = ["E1", "E2", "E3"]



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$RichTextLabel.text = str(player_deck.size())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func draw_card():	
	var card_drawn = player_deck[0]
	player_deck.erase(card_drawn)
	
	# All card drawn
	if player_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$Sprite2D.visible = false
		$RichTextLabel.visible = false
	
	$RichTextLabel.text = str(player_deck.size())
	var card_scene = preload(CARD_SCENE_PATH)	
	var new_card = card_scene.instantiate()
	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
