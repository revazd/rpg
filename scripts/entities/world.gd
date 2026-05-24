extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D        = $Player/Camera2D

var _hud = null


func _ready() -> void:
	_hud = get_node_or_null("HUD")

	if not player.interacted.is_connected(_on_player_interacted):
		player.interacted.connect(_on_player_interacted)

	if DialogueManager:
		if not DialogueManager.dialogue_started.is_connected(_on_dialogue_started):
			DialogueManager.dialogue_started.connect(_on_dialogue_started)
		if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
			DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed   = 6.0
	_setup_camera_limits()

	if SaveManager.has_save():
		var ok := SaveManager.load_game()
		if not ok:
			push_warning("World: echec du chargement.")

	# Demarre les quetes disponibles sans prerequis
	QuestManager.start_quest("main_01")
	QuestManager.start_quest("side_bread")
	QuestManager.start_quest("side_gateau")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("save_game"):
		SaveManager.save_game()
		_notify("Partie sauvegardee.")


func _setup_camera_limits() -> void:
	var tilemap: TileMap = get_node_or_null("TileMap")
	if tilemap == null:
		return
	var used_rect := tilemap.get_used_rect()
	var tile_size := tilemap.tile_set.tile_size
	camera.limit_left   = used_rect.position.x * tile_size.x
	camera.limit_top    = used_rect.position.y * tile_size.y
	camera.limit_right  = used_rect.end.x * tile_size.x
	camera.limit_bottom = used_rect.end.y * tile_size.y


func _on_player_interacted(area: Area2D) -> void:
	if area.is_in_group("npc"):
		var npc_id: String = area.get_meta("npc_id", "")
		var path: String   = area.get_meta("dialogue_file", "")

		# Notifie le QuestManager
		if npc_id != "":
			QuestManager.notify_talk(npc_id)
			# Verifie si le joueur peut livrer quelque chose a ce PNJ
			_try_deliver_to(npc_id)

		if path != "" and ResourceLoader.exists(path):
			var dialogue_res: DialogueResource = load(path)
			var cue: String = area.get_meta("dialogue_cue", "start")
			DialogueManager.show_dialogue_balloon(dialogue_res, cue)

	elif area.is_in_group("oven"):
		var oven_node = area if area.has_method("interact") else area.get_parent()
		if oven_node.has_method("interact"):
			oven_node.interact()

	elif area.is_in_group("shop"):
		var shop_ui = get_node_or_null("ShopUI")
		if shop_ui:
			shop_ui.open_shop()

	elif area.is_in_group("chest"):
		var loot: String = area.get_meta("loot", "")
		if loot != "":
			Inventory.add_item(loot)
			QuestManager.notify_collect(loot, 1)
			_notify("Tu as trouve : " + loot)


func _try_deliver_to(npc_id: String) -> void:
	for quest in QuestManager.get_active_quests():
		for obj in quest["objectives"]:
			if obj["type"] == "deliver" and obj["npc_id"] == npc_id and not obj["done"]:
				QuestManager.notify_deliver(obj["item_id"], npc_id)
				return


func _on_dialogue_started(_resource: DialogueResource) -> void:
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	player.set_physics_process(true)


func _notify(msg: String) -> void:
	if _hud and _hud.has_method("show_notification"):
		_hud.show_notification(msg)
	else:
		print("[World] ", msg)
