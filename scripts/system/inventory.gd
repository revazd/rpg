extends Node

signal inventory_changed
signal hotbar_changed
signal money_changed(new_amount: int)

const MAX_HOTBAR := 5

var slots: Array = []
var hotbar: Array = []
var money: int = 0


func _ready() -> void:
	# Initialise la hotbar avec des slots vides
	hotbar.clear()
	for i in range(MAX_HOTBAR):
		hotbar.append({})


func _is_empty(slot: Dictionary) -> bool:
	return slot.is_empty()


# ── Argent ────────────────────────────────────────────────────────────────────

func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)


func spend_money(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	money_changed.emit(money)
	return true


# ── Inventaire principal ──────────────────────────────────────────────────────

func add_item(item_id: String, quantity: int = 1) -> void:
	var item: ItemData = ItemRegistry.get_item(item_id)
	if item == null:
		push_error("Inventory: item inconnu -> " + item_id)
		return

	if item.is_tool:
		_add_to_hotbar(item_id)
		return

	var remaining: int = quantity

	for slot in slots:
		if slot["item_id"] == item_id:
			var item_data: ItemData = ItemRegistry.get_item(item_id)
			var current_qty: int = int(slot["quantity"])
			var max_s: int = item_data.max_stack
			var space: int = max_s - current_qty
			if space > 0:
				var added: int = min(remaining, space)
				slot["quantity"] = current_qty + added
				remaining -= added
				if remaining <= 0:
					inventory_changed.emit()
					return

	while remaining > 0:
		var item_data: ItemData = ItemRegistry.get_item(item_id)
		var max_s: int = item_data.max_stack
		var batch: int = min(remaining, max_s)
		slots.append({"item_id": item_id, "quantity": batch})
		remaining -= batch

	inventory_changed.emit()


func remove_item(item_id: String, quantity: int = 1) -> bool:
	if not has_item(item_id, quantity):
		return false
	var remaining: int = quantity
	for i in range(slots.size() - 1, -1, -1):
		var slot: Dictionary = slots[i]
		if slot["item_id"] != item_id:
			continue
		var current_qty: int = int(slot["quantity"])
		var taken: int = min(current_qty, remaining)
		slot["quantity"] = current_qty - taken
		remaining -= taken
		if slot["quantity"] <= 0:
			slots.remove_at(i)
		if remaining <= 0:
			break
	inventory_changed.emit()
	return true


func has_item(item_id: String, quantity: int = 1) -> bool:
	var total: int = 0
	for slot in slots:
		if slot["item_id"] == item_id:
			total += int(slot["quantity"])
	return total >= quantity


func count_item(item_id: String) -> int:
	var total: int = 0
	for slot in slots:
		if slot["item_id"] == item_id:
			total += int(slot["quantity"])
	return total


# ── Hotbar ────────────────────────────────────────────────────────────────────

func _add_to_hotbar(item_id: String) -> void:
	for i in range(MAX_HOTBAR):
		if not _is_empty(hotbar[i]) and hotbar[i]["item_id"] == item_id:
			return
	for i in range(MAX_HOTBAR):
		if _is_empty(hotbar[i]):
			hotbar[i] = {"item_id": item_id, "quantity": 1}
			hotbar_changed.emit()
			return
	push_warning("Inventory: hotbar pleine")


func set_hotbar_slot(index: int, item_id: String) -> void:
	if index < 0 or index >= MAX_HOTBAR:
		return
	if item_id == "":
		hotbar[index] = {}
	else:
		hotbar[index] = {"item_id": item_id, "quantity": 1}
	hotbar_changed.emit()


# ── Serialisation ─────────────────────────────────────────────────────────────

func to_dict() -> Dictionary:
	var hotbar_data: Array = []
	for slot in hotbar:
		hotbar_data.append(slot)
	return {
		"money":  money,
		"slots":  slots.duplicate(true),
		"hotbar": hotbar_data,
	}


func from_dict(data: Dictionary) -> void:
	if not data is Dictionary or data.is_empty():
		return
	money = int(data.get("money", 0))
	slots = []
	for s in data.get("slots", []):
		if s is Dictionary and s.has("item_id"):
			slots.append(s)
	var hb: Array = data.get("hotbar", [])
	hotbar.clear()
	for i in range(MAX_HOTBAR):
		if i < hb.size() and hb[i] is Dictionary:
			hotbar.append(hb[i])
		else:
			hotbar.append({})
	inventory_changed.emit()
	hotbar_changed.emit()
	money_changed.emit(money)
