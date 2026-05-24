extends Node

signal game_saved
signal game_loaded

const SAVE_PATH := "user://save.json"
const AUTO_SAVE_INTERVAL := 120.0

var _auto_save_timer: float = 0.0


func _process(delta: float) -> void:
	_auto_save_timer += delta
	if _auto_save_timer >= AUTO_SAVE_INTERVAL:
		_auto_save_timer = 0.0
		save_game()
		var hud = _get_hud()
		if hud:
			hud.show_notification("Partie sauvegardee automatiquement.")


func save_game() -> void:
	var inv = get_node_or_null("/root/Inventory")
	var xp = get_node_or_null("/root/XPManager")
	var quests = get_node_or_null("/root/QuestManager")
	var data := {
		"version": 2,
		"inventory": inv.to_dict() if inv else {},
		"xp": xp.to_dict() if xp else {},
		"quests": quests.to_dict() if quests else {},
"		recipes": get_node_or_null("/root/RecipeManager").to_dict() if get_node_or_null("/root/RecipeManager") else [],
		"player_pos": _save_player_pos(),
	}
	var json_str := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: impossible d ouvrir le fichier.")
		return
	file.store_string(json_str)
	file.close()
	game_saved.emit()
	print("Sauvegarde OK -> ", SAVE_PATH)


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var json_str := file.get_as_text()
	file.close()
	if json_str.strip_edges() == "":
		return false
	var json := JSON.new()
	if json.parse(json_str) != OK:
		push_error("SaveManager: JSON invalide.")
		return false
	var data = json.get_data()
	if not data is Dictionary:
		return false
	var inv = get_node_or_null("/root/Inventory")
	var xp = get_node_or_null("/root/XPManager")
	var quests = get_node_or_null("/root/QuestManager")
	if inv:
		inv.from_dict(data.get("inventory", {}))
	if xp:
		xp.from_dict(data.get("xp", {}))
	if quests:
		quests.from_dict(data.get("quests", {}))
	_load_player_pos(data.get("player_pos", {}))
	game_loaded.emit()
	print("Sauvegarde chargee.")
	var recipes = get_node_or_null("/root/RecipeManager")
	if recipes:
		recipes.from_dict(data.get("recipes", []))
	return true



func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func _save_player_pos() -> Dictionary:
	var p = _get_player()
	if p == null:
		return {}
	return {"x": p.position.x, "y": p.position.y}


func _load_player_pos(data: Dictionary) -> void:
	if data.is_empty():
		return
	var p = _get_player()
	if p == null:
		return
	p.position = Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))


func _get_player():
	var scene = get_tree().current_scene
	return scene.get_node_or_null("Player") if scene else null


func _get_hud():
	var scene = get_tree().current_scene
	return scene.get_node_or_null("HUD") if scene else null
