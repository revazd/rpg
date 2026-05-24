extends Node

var _items: Dictionary = {}


func _ready() -> void:
	_register_all()


func get_item(item_id: String) -> ItemData:
	return _items.get(item_id, null)


func _register(item: ItemData) -> void:
	_items[item.id] = item


func _make(id: String, item_name: String, type: ItemData.ItemType,
		   buy: int, sell: int) -> ItemData:
	var item := ItemData.new()
	item.id         = id
	item.item_name  = item_name
	item.type       = type
	item.buy_price  = buy
	item.sell_price = sell
	return item


func _register_all() -> void:
	_register(_make("pate_pain",    "Pate a pain",      ItemData.ItemType.INGREDIENT, 5,  2))
	_register(_make("oeuf",         "Oeuf",             ItemData.ItemType.INGREDIENT, 3,  1))
	_register(_make("farine",       "Farine",           ItemData.ItemType.INGREDIENT, 2,  1))
	_register(_make("beurre",       "Beurre",           ItemData.ItemType.INGREDIENT, 4,  2))
	_register(_make("sucre",        "Sucre",            ItemData.ItemType.INGREDIENT, 2,  1))
	_register(_make("pomme",        "Pomme",            ItemData.ItemType.INGREDIENT, 3,  1))
	_register(_make("pain_cuit",    "Pain cuit",        ItemData.ItemType.COOKED,     0,  8))
	_register(_make("gateau",       "Gateau",           ItemData.ItemType.COOKED,     0, 15))
	_register(_make("tarte_pommes", "Tarte aux pommes", ItemData.ItemType.COOKED,     0, 20))
	_register(_make("pain_brule",   "Pain brule",       ItemData.ItemType.MISC,       0,  0))
	_register(_make("gateau_brule", "Gateau brule",     ItemData.ItemType.MISC,       0,  0))
	_register(_make("tarte_brulee", "Tarte brulee",     ItemData.ItemType.MISC,       0,  0))

	var couteau := _make("couteau", "Couteau", ItemData.ItemType.TOOL, 0, 0)
	couteau.is_tool   = true
	couteau.max_stack = 1
	_register(couteau)
