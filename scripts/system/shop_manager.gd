extends Node

# Singleton : ShopManager
# Catalogue des items achetables en boutique

signal purchase_failed(reason: String)
signal purchase_success(item_id: String, quantity: int)

# Catalogue : liste de { item_id, quantity_available (-1 = infini) }
# Modifie ce tableau pour personaliser ta boutique
var catalogue: Array[Dictionary] = [
	{"item_id": "pate_pain", "available": -1},
	{"item_id": "oeuf",      "available": -1},
	{"item_id": "farine",    "available": -1},
	{"item_id": "beurre",    "available": -1},
	{"item_id": "sucre",     "available": -1},
	{"item_id": "pomme",     "available": -1},
]


func buy(item_id: String, quantity: int = 1) -> bool:
	# Verifie que l item est au catalogue
	var entry := _find_entry(item_id)
	if entry.is_empty():
		purchase_failed.emit("Cet article n est pas disponible.")
		return false

	# Verifie le stock
	if entry["available"] != -1 and entry["available"] < quantity:
		purchase_failed.emit("Stock insuffisant.")
		return false

	# Verifie l argent
	var item := ItemRegistry.get_item(item_id)
	if item == null:
		return false
	var total_cost := item.buy_price * quantity
	if not Inventory.spend_money(total_cost):
		purchase_failed.emit("Pas assez d argent ! (Besoin : " + str(total_cost) + " pi)")
		return false

	# Debite le stock si fini
	if entry["available"] != -1:
		entry["available"] -= quantity

	Inventory.add_item(item_id, quantity)
	purchase_success.emit(item_id, quantity)
	return true


func _find_entry(item_id: String) -> Dictionary:
	for entry in catalogue:
		if entry["item_id"] == item_id:
			return entry
	return {}
