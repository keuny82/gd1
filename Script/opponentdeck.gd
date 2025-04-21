extends Node2D

const CARD_SCENE_PATH = "res://Scenes/OpponentCard.tscn"
const CARD_DRAW_SPEED = 0.5
const STARTING_HAND_SIZE = 5
#var player_deck = ["E1", "E2", "E3", "E4", "E5", "E6", "E7", "E8", "E9", "E10"
				#, "M1", "M2", "M3", "M4", "M5", "M6", "M7", "M8", "M9", "M10"
				#, "T1", "T2", "T3", "T4", "T5", "T6", "T7", "T8", "T9", "T10"
				#, "P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8", "P9", "P10"]
var opponent_deck = ["N102", "N102", "Delta", "N102", "N102", "Delta", "N102", "N102"]
var card_database_reference


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	opponent_deck.shuffle()
	$RichTextLabel.text = str(opponent_deck.size())
	card_database_reference = preload("res://Script/carddatabase.gd")
	for i in range(STARTING_HAND_SIZE):
		draw_card()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func draw_card():
	var card_drawn_name = opponent_deck[0]
	opponent_deck.erase(card_drawn_name)
	
	# All card drawn
	if opponent_deck.size() == 0:
		$Sprite2D.visible = false
		$RichTextLabel.visible = false
	
	$RichTextLabel.text = str(opponent_deck.size())
	var card_scene = preload(CARD_SCENE_PATH)	
	var new_card = card_scene.instantiate()
	var card_image_path = str("res://Asset/Cards/" + card_drawn_name + ".png")
	new_card.get_node("CardImage").texture = load(card_image_path)
	new_card.attack = card_database_reference.CARDS[card_drawn_name][0]
	new_card.get_node("Attack").text = str(new_card.attack)
	new_card.health = card_database_reference.CARDS[card_drawn_name][1]
	new_card.get_node("Health").text = str(new_card.health)
	new_card.card_type = card_database_reference.CARDS[card_drawn_name][2]
	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	$"../OpponentHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
	#new_card.get_node("AnimationPlayer").play("cardflip")
