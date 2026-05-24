extends CanvasLayer

# Arborescence :
#   CanvasLayer (QuestUI)
#   Panel
#   VBoxContainer
#   ├── Label (title)              "Journal de quetes"
#   ├── TabContainer
#   │   ├── VBoxContainer "Principales"
#   │   │   └── ItemList (main_list)
#   │   └── VBoxContainer "Secondaires"
#   │       └── ItemList (side_list)
#   ├── RichTextLabel (detail_label)
#   └── Button (close_btn)

@onready var main_list: ItemList         = $Panel/VBoxContainer/Tabs/Principales/MainList
@onready var side_list: ItemList         = $Panel/VBoxContainer/Tabs/Secondaires/SideList
@onready var detail_label: RichTextLabel = $Panel/VBoxContainer/DetailLabel
@onready var close_btn: Button           = $Panel/VBoxContainer/CloseBtn


func _ready() -> void:
	close_btn.pressed.connect(hide)
	main_list.item_selected.connect(_on_main_selected)
	side_list.item_selected.connect(_on_side_selected)
	QuestManager.quest_started.connect(func(_q): refresh())
	QuestManager.quest_completed.connect(func(_q): refresh())
	QuestManager.quest_objective_updated.connect(func(_q, _o): refresh())
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_journal"):
		if visible:
			hide()
		else:
			refresh()
			show()


func refresh() -> void:
	main_list.clear()
	side_list.clear()
	detail_label.text = ""

	for quest in QuestManager.get_active_quests():
		var label: String = quest["title"]
		if quest["type"] == "main":
			main_list.add_item("[ ] " + label)
			main_list.set_item_metadata(main_list.item_count - 1, quest)
		else:
			side_list.add_item("[ ] " + label)
			side_list.set_item_metadata(side_list.item_count - 1, quest)

	for quest_id in QuestManager.get_completed_ids():
		var quest = QuestManager.all_quests.get(quest_id, {})
		if quest.is_empty():
			continue
		if quest["type"] == "main":
			main_list.add_item("[X] " + quest["title"])
			main_list.set_item_metadata(main_list.item_count - 1, quest)
		else:
			side_list.add_item("[X] " + quest["title"])
			side_list.set_item_metadata(side_list.item_count - 1, quest)


func _on_main_selected(index: int) -> void:
	var quest = main_list.get_item_metadata(index)
	if quest:
		_show_detail(quest)


func _on_side_selected(index: int) -> void:
	var quest = side_list.get_item_metadata(index)
	if quest:
		_show_detail(quest)


func _show_detail(quest: Dictionary) -> void:
	var text: String = "[b]" + quest["title"] + "[/b]\n"
	text += quest["description"] + "\n\n"
	text += "[b]Objectifs :[/b]\n"
	for obj in quest["objectives"]:
		var line: String = ""
		if obj["type"] == "talk":
			line = ("[X] " if obj["done"] else "[ ] ") + obj["label"]
		elif obj["type"] == "collect":
			line = "[" + str(obj["current"]) + "/" + str(obj["amount"]) + "] " + obj["label"]
		elif obj["type"] == "deliver":
			line = ("[X] " if obj["done"] else "[ ] ") + obj["label"]
		text += line + "\n"
	var rewards: Dictionary = quest["rewards"]
	text += "\n[b]Recompenses :[/b] "
	text += str(rewards.get("xp", 0)) + " XP, "
	text += str(rewards.get("money", 0)) + " pi"
	if rewards.has("items") and not rewards["items"].is_empty():
		for item_id in rewards["items"]:
			var item = ItemRegistry.get_item(item_id)
			text += ", " + (item.item_name if item else item_id) + " x" + str(rewards["items"][item_id])
	detail_label.text = text
