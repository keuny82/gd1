extends Node

const SMALL_CARD_SCALE = 0.6
const CARD_MOVE_SPEED = 0.2


var battle_timer
var empty_nikke_card_slots = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0
	
	empty_nikke_card_slots.append($"../CardSlots/OpponentCardSlot1")
	empty_nikke_card_slots.append($"../CardSlots/OpponentCardSlot2")
	empty_nikke_card_slots.append($"../CardSlots/OpponentCardSlot3")
	empty_nikke_card_slots.append($"../CardSlots/OpponentCardSlot4")
	empty_nikke_card_slots.append($"../CardSlots/OpponentCardSlot5")

func _on_end_turn_button_pressed() -> void:
	opponent_turn()
	
func opponent_turn():
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false
	
	battle_timer.start()
	await battle_timer.timeout
	
	# 1장 뽑고 1초 쉬고
	if $"../OpponentDeck".opponent_deck.size() != 0:
		$"../OpponentDeck".draw_card()
		battle_timer.start()
		await battle_timer.timeout
	
	# 빈칸이 없으면 end turn
	if empty_nikke_card_slots.size() == 0:
		end_opponent_turn()
		return
	
	# 공격력 가장 높은 것 부터 플레이 하도록
	try_play_card_with_highest_attack()
	
	# End turn
	end_opponent_turn()

func try_play_card_with_highest_attack():
	var opponent_hand = $"../OpponentHand".opponent_hand	
	if opponent_hand.size() == 0:
		end_opponent_turn()
	
	var random_empty_monster_card_slot = empty_nikke_card_slots[randi_range(0, empty_nikke_card_slots.size() - 1)]
	empty_nikke_card_slots.erase(random_empty_monster_card_slot)
	
	var card_with_highest_atk = opponent_hand[0]
	for card in opponent_hand:
		if card.attack > card_with_highest_atk.attack:
			card_with_highest_atk = card
	
	# 애니메이션 처리
	var tween1 = get_tree().create_tween()
	tween1.tween_property(card_with_highest_atk, "position", random_empty_monster_card_slot.position, CARD_MOVE_SPEED)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(card_with_highest_atk, "scale", Vector2(SMALL_CARD_SCALE, SMALL_CARD_SCALE), CARD_MOVE_SPEED)
	card_with_highest_atk.get_node("AnimationPlayer").play("cardflip")
	
	# 상대 핸드에서 지우기
	$"../OpponentHand".remove_card_from_hand(card_with_highest_atk)
	
	battle_timer.start()
	await battle_timer.timeout

func end_opponent_turn():
	$"../Deck".reset_draw()
	$"../CardManager".reset_played()
	$"../EndTurnButton".disabled = false
	$"../EndTurnButton".visible = true
