extends Node

signal quest_started(quest: Dictionary)
signal quest_objective_updated(quest: Dictionary, objective: Dictionary)
signal quest_completed(quest: Dictionary)
signal quest_failed(quest: Dictionary)

var all_quests: Dictionary = {}
var active_quests: Dictionary = {}
var completed_quests: Array = []


func _ready() -> void:
	print("QuestManager OK")
	_register_all_quests()


func _get_inventory():
	return get_node_or_null("/root/Inventory")

func _get_xp():
	return get_node_or_null("/root/XPManager")

func _get_recipes():
	return get_node_or_null("/root/RecipeManager")

func _get_hud():
	var scene = get_tree().current_scene
	return scene.get_node_or_null("HUD") if scene else null


func _register_all_quests() -> void:
	_register({
		"id": "main_01", "type": "main",
		"title": "Premiers pas",
		"description": "Parle au boulanger du village.",
		"objectives": [
			{"type": "talk", "npc_id": "baker", "label": "Parler au boulanger", "done": false}
		],
		"rewards": {"xp": 50, "money": 20, "items": {}},
		"unlocks": ["main_02", "side_bread"], "requires": []
	})
	_register({
		"id": "main_02", "type": "main",
		"title": "Le pain quotidien",
		"description": "Cuisine un pain et livre-le au boulanger.",
		"objectives": [
			{"type": "collect", "item_id": "pain_cuit", "label": "Cuisiner un pain", "amount": 1, "current": 0},
			{"type": "deliver", "item_id": "pain_cuit", "amount": 1, "npc_id": "baker", "label": "Livrer le pain au boulanger", "done": false}
		],
		"rewards": {"xp": 100, "money": 50, "items": {"pate_pain": 2}},
		"unlocks": ["main_03"], "requires": ["main_01"]
	})
	_register({
		"id": "main_03", "type": "main",
		"title": "La tarte du chef",
		"description": "Cuisine une tarte aux pommes pour le festival.",
		"objectives": [
			{"type": "collect", "item_id": "tarte_pommes", "label": "Cuisiner une tarte", "amount": 1, "current": 0},
			{"type": "deliver", "item_id": "tarte_pommes", "amount": 1, "npc_id": "chef", "label": "Livrer la tarte au chef", "done": false}
		],
		"rewards": {"xp": 200, "money": 100, "items": {}, "unlock_recipe": "Tarte aux pommes"},
		"unlocks": [], "requires": ["main_02"]
	})
	_register({
		"id": "side_bread", "type": "side",
		"title": "Approvisionnement",
		"description": "Ramasse 3 pommes dans le verger.",
		"objectives": [
			{"type": "collect", "item_id": "pomme", "label": "Ramasser des pommes", "amount": 3, "current": 0}
		],
		"rewards": {"xp": 30, "money": 10, "items": {"sucre": 1}},
		"unlocks": [], "requires": []
	})
	_register({
		"id": "side_gateau", "type": "side",
		"title": "Anniversaire surprise",
		"description": "Cuisine un gateau pour l anniversaire du maire.",
		"objectives": [
			{"type": "collect", "item_id": "gateau", "label": "Cuisiner un gateau", "amount": 1, "current": 0},
			{"type": "deliver", "item_id": "gateau", "amount": 1, "npc_id": "mayor", "label": "Livrer le gateau au maire", "done": false}
		],
		"rewards": {"xp": 80, "money": 60, "items": {}, "unlock_recipe": "Gateau"},
		"unlocks": [], "requires": []
	})


func _register(quest: Dictionary) -> void:
	all_quests[quest["id"]] = quest


func start_quest(quest_id: String) -> bool:
	if not all_quests.has(quest_id):
		push_warning("QuestManager: quete inconnue -> " + quest_id)
		return false
	if active_quests.has(quest_id) or completed_quests.has(quest_id):
		return false
	var quest: Dictionary = all_quests[quest_id].duplicate(true)
	for req in quest["requires"]:
		if not completed_quests.has(req):
			return false
	active_quests[quest_id] = quest
	quest_started.emit(quest)
	var hud = _get_hud()
	if hud:
		hud.show_notification("[Quete] " + quest["title"] + " commencee !")
	return true


func notify_talk(npc_id: String) -> void:
	for quest_id in active_quests:
		var quest: Dictionary = active_quests[quest_id]
		for obj in quest["objectives"]:
			if obj["type"] == "talk" and obj["npc_id"] == npc_id and not obj["done"]:
				obj["done"] = true
				quest_objective_updated.emit(quest, obj)
				_check_completion(quest_id)


func notify_collect(item_id: String, amount: int = 1) -> void:
	for quest_id in active_quests:
		var quest: Dictionary = active_quests[quest_id]
		for obj in quest["objectives"]:
			if obj["type"] == "collect" and obj["item_id"] == item_id:
				obj["current"] = min(int(obj["current"]) + amount, int(obj["amount"]))
				quest_objective_updated.emit(quest, obj)
				_check_completion(quest_id)


func notify_deliver(item_id: String, npc_id: String) -> bool:
	var inv = _get_inventory()
	if inv == null:
		return false
	for quest_id in active_quests:
		var quest: Dictionary = active_quests[quest_id]
		for obj in quest["objectives"]:
			if obj["type"] == "deliver" and obj["item_id"] == item_id and obj["npc_id"] == npc_id and not obj["done"]:
				if inv.has_item(item_id, int(obj["amount"])):
					inv.remove_item(item_id, int(obj["amount"]))
					obj["done"] = true
					quest_objective_updated.emit(quest, obj)
					_check_completion(quest_id)
					return true
	return false


func _check_completion(quest_id: String) -> void:
	var quest: Dictionary = active_quests[quest_id]
	for obj in quest["objectives"]:
		if obj["type"] == "talk" and not obj["done"]:
			return
		if obj["type"] == "collect" and int(obj["current"]) < int(obj["amount"]):
			return
		if obj["type"] == "deliver" and not obj["done"]:
			return
	_complete_quest(quest_id)


func _complete_quest(quest_id: String) -> void:
	var quest: Dictionary = active_quests[quest_id]
	active_quests.erase(quest_id)
	completed_quests.append(quest_id)

	var rewards: Dictionary = quest["rewards"]
	var inv = _get_inventory()
	var xp = _get_xp()
	var recipes = _get_recipes()

	if inv and rewards.has("money"):
		inv.add_money(int(rewards["money"]))
	if xp and rewards.has("xp"):
		xp.add_xp(int(rewards["xp"]))
	if inv and rewards.has("items"):
		for item_id in rewards["items"]:
			inv.add_item(item_id, int(rewards["items"][item_id]))
	if recipes and rewards.has("unlock_recipe"):
		recipes.unlock_recipe(rewards["unlock_recipe"])

	quest_completed.emit(quest)
	var hud = _get_hud()
	if hud:
		hud.show_notification("[Quete accomplie] " + quest["title"] + " ! +" + str(rewards.get("xp", 0)) + " XP +" + str(rewards.get("money", 0)) + " pi")

	for next_id in quest["unlocks"]:
		start_quest(next_id)


func get_active_quests() -> Array:
	return active_quests.values()


func get_completed_ids() -> Array:
	return completed_quests


func to_dict() -> Dictionary:
	return {
		"active": active_quests.duplicate(true),
		"completed": completed_quests.duplicate()
	}


func from_dict(data: Dictionary) -> void:
	if data.is_empty():
		return
	completed_quests = data.get("completed", [])
	active_quests = {}
	var saved_active: Dictionary = data.get("active", {})
	for quest_id in saved_active:
		active_quests[quest_id] = saved_active[quest_id]
