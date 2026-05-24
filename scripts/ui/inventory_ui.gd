extends CanvasLayer

# UI inventaire + hotbar
# Arborescence attendue :
#   CanvasLayer (InventoryUI)
#   ├── InventoryPanel (Panel)      inventaire principal
#   │   VBoxContainer
#   │   ├── Label                   "Inventaire"
#   │   ├── GridContainer (grid)    grille de slots
#   │   └── Button (close_btn)
#   └── HotbarPanel (Panel)         toujours visible en bas
#       HBoxContainer (hotbar_box)  MAX_HOTBAR boutons

@onready var grid: GridContainer       = $InventoryPanel/VBoxContainer/Grid
@onready var inv_panel: Panel          = $InventoryPanel
@onready var close_btn: Button         = $InventoryPanel/VBoxContainer/CloseBtn
@onready var hotbar_box: HBoxContainer = $HotbarPanel/HotbarBox

const SLOT_SIZE := 64

var _hotbar_buttons: Array[Button] = []


func _ready() -> void:
	close_btn.pressed.connect(toggle_inventory)
	Inventory.inventory_changed.connect(_refresh_inventory)
	Inventory.hotbar_changed.connect(_refresh_hotbar)
	_build_hotbar()
	_refresh_hotbar()
	inv_panel.hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_inventory"):
		toggle_inventory()


func toggle_inventory() -> void:
	if inv_panel.visible:
		inv_panel.hide()
	else:
		_refresh_inventory()
		inv_panel.show()


# ── Inventaire principal ──────────────────────────────────────────────────────

func _refresh_inventory() -> void:
	for child in grid.get_children():
		child.queue_free()

	for slot in Inventory.slots:
		var item := ItemRegistry.get_item(slot["item_id"])
		if item == null:
			continue
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		btn.text = item.item_name + "\nx" + str(slot["quantity"])
		btn.tooltip_text = item.description
		grid.add_child(btn)


# ── Hotbar ────────────────────────────────────────────────────────────────────

func _build_hotbar() -> void:
	for child in hotbar_box.get_children():
		child.queue_free()
	_hotbar_buttons.clear()

	for i in range(Inventory.MAX_HOTBAR):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		btn.text = str(i + 1)
		hotbar_box.add_child(btn)
		_hotbar_buttons.append(btn)

func _refresh_hotbar() -> void:
	for i in range(Inventory.MAX_HOTBAR):
		var slot = Inventory.hotbar[i]
		if slot == null or not slot is Dictionary or slot.is_empty():
			_hotbar_buttons[i].text = str(i + 1)
			_hotbar_buttons[i].tooltip_text = ""
		else:
			var item = ItemRegistry.get_item(slot["item_id"])
			_hotbar_buttons[i].text = item.item_name if item else "?"
			_hotbar_buttons[i].tooltip_text = item.description if item else ""
