extends Node

const SMALL_CARD_SCALE = 0.6
const CARD_MOVE_SPEED = 0.2
const STARTING_HEALTH = 10
const BATTLE_POS_OFFSET = 25

var battle_timer
var empty_nikke_card_slots = []
var player_cards_on_battlefield = []
var opponent_cards_on_battlefield = []
var player_cards_that_attacked_this_turn = []
var player_health
var opponent_health
var is_opponents_turn = false
var player_is_attacking = false

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
	
	player_health = STARTING_HEALTH
	$"../PlayerHealth".text = str(player_health)
	opponent_health = STARTING_HEALTH
	$"../OpponentHealth".text = str(opponent_health)

func _on_end_turn_button_pressed() -> void:
	is_opponents_turn = true
	$"../CardManager".unselected_selected_nikke()
	player_cards_that_attacked_this_turn = []
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
	
	# 빈칸이 있으면 카드를 플레이
	if empty_nikke_card_slots.size() != 0:
		# 공격력 가장 높은 것 부터 플레이 하도록
		await try_play_card_with_highest_attack()	
	
	# 공격!!
	if opponent_cards_on_battlefield.size() != 0:
		var opponent_card_to_attack = opponent_cards_on_battlefield.duplicate()
		for card in opponent_card_to_attack:
			if player_cards_on_battlefield.size() != 0:
				var card_to_attack = player_cards_on_battlefield.pick_random()
				await attack(card, card_to_attack, "Opponent")
			else:
				await direct_attack(card, "Opponent")
	
	# End turn
	end_opponent_turn()


# 플레이어 공격!!!
func direct_attack(attacking_card, attacker):
	var new_pos_y
	if attacker == "Opponent":
		new_pos_y = 1080
	else:
		$"../EndTurnButton".disabled = true
		$"../EndTurnButton".visible = false
		player_is_attacking = true
		new_pos_y = 0
		player_cards_that_attacked_this_turn.append(attacking_card)

	var new_pos = Vector2(attacking_card.position.x, new_pos_y)
	attacking_card.z_index = 5
	# 공격하고 돌아오는 애니메이션
	var	tween1 = get_tree().create_tween()
	tween1.tween_property(attacking_card, "position", new_pos, CARD_MOVE_SPEED)
	await wait(0.15)
	
	if attacker == "Opponent":
		player_health = max(0, player_health - attacking_card.attack)
		$"../PlayerHealth".text = str(player_health)
	else:
		opponent_health = max(0, opponent_health - attacking_card.attack)
		$"../OpponentHealth".text = str(opponent_health)
		
	var	tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_slot_card_is_in.position, CARD_MOVE_SPEED)
	
	attacking_card.z_index = 0
	await wait(1.0)
	
	if attacker == "Player":
		player_is_attacking = false
		$"../EndTurnButton".disabled = false
		$"../EndTurnButton".visible = true

# 카드 공격
func attack(attacking_card, defending_card, attacker):
	if attacker == "Player":
		player_is_attacking = true
		$"../EndTurnButton".disabled = true
		$"../EndTurnButton".visible = false
		$"../CardManager".selected_nikke = null
		player_cards_that_attacked_this_turn.append(attacking_card)
	
	# 카드를 공격하면
	attacking_card.z_index = 5
	var new_pos = Vector2(defending_card.position.x, defending_card.position.y + BATTLE_POS_OFFSET)
	# 공격하고 돌아오는 애니메이션
	var	tween1 = get_tree().create_tween()
	tween1.tween_property(attacking_card, "position", new_pos, CARD_MOVE_SPEED)
	await wait(0.15)
	var	tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_slot_card_is_in.position, CARD_MOVE_SPEED)
	
	# 수치 계산
	defending_card.health = max(0, defending_card.health - attacking_card.attack)
	defending_card.get_node("Health").text =  str(defending_card.health)
	attacking_card.health = max(0, attacking_card.health - defending_card.attack)
	attacking_card.get_node("Health").text =  str(attacking_card.health)

	await wait(1.0)
	attacking_card.z_index = 0
	
	
	# 데미지 계산 후 health 0 카드 처리
	var card_was_destroyed = false
	# 공격카드 체크
	if attacking_card.health == 0:
		destroy_card(attacking_card, attacker)
		card_was_destroyed = true
		
	# 수비 카드 체크
	if defending_card.health == 0:
		if attacker == "Player":
			destroy_card(defending_card, "Opponent")
		else:
			destroy_card(defending_card, "Player")
		card_was_destroyed = true
		
	if card_was_destroyed:
		await wait(1.0)
		
	if attacker == "Player":
		player_is_attacking = false
		$"../EndTurnButton".disabled = false
		$"../EndTurnButton".visible = true


func destroy_card(card, card_owner):
	# 카드를 무덤으로
	var new_pos
	if card_owner == "Player":
		card.get_node("Area2D/CollisionShape2D").disabled = true
		new_pos = $"../PlayerDiscard".position
		if card in player_cards_on_battlefield:
			player_cards_on_battlefield.erase(card)
		card.card_slot_card_is_in.get_node("Area2D/CollisionShape2D").disabled = false
	else:
		new_pos = $"../OpponentDiscard".position
		if card in opponent_cards_on_battlefield:
			opponent_cards_on_battlefield.erase(card)
	
	card.card_slot_card_is_in.card_in_slot = false
	card.card_slot_card_is_in = null
	var	tween1 = get_tree().create_tween()
	tween1.tween_property(card, "position", new_pos, CARD_MOVE_SPEED)


func opponent_card_selected(defending_card):
	var attacking_card = $"../CardManager".selected_nikke
	if attacking_card:
		if defending_card in opponent_cards_on_battlefield:
			if player_is_attacking == false:
				$"../CardManager".selected_nikke = null
				attack(attacking_card, defending_card, "Player")


func try_play_card_with_highest_attack():
	var opponent_hand = $"../OpponentHand".opponent_hand	
	if opponent_hand.size() == 0:
		end_opponent_turn()
	
	var random_empty_monster_card_slot = empty_nikke_card_slots.pick_random()
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
	card_with_highest_atk.card_slot_card_is_in = random_empty_monster_card_slot
	opponent_cards_on_battlefield.append(card_with_highest_atk)
	await wait(1.0)

func wait(wait_time):
	battle_timer.wait_time = wait_time
	battle_timer.start()
	await battle_timer.timeout



func end_opponent_turn():
	$"../Deck".reset_draw()
	$"../CardManager".reset_played()
	is_opponents_turn = false
	$"../EndTurnButton".disabled = false
	$"../EndTurnButton".visible = true
