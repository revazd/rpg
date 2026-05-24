extends CanvasLayer

# UI de la boutique
# Arborescence attendue :
#   CanvasLayer (ShopUI)
#   Panel
#   VBoxContainer
#   ├── Label (title)
#   ├── Label (money_label)        "Or : 50 pi"
#   ├── ItemList (shop_list)       liste des articles
#   ├── HBoxContainer
#   │   ├── Label                  "Quantite :"
#   │   └── SpinBox (qty_spinbox)
#   ├── Label (price_label)        "Prix : X pi"
#   ├── HBoxContainer
#   │   ├── Button (buy_btn)       "Acheter"
#   │   └── Button (close_btn)    "Fermer"

@onready var money_label: Label    = $Panel/VBoxContainer/MoneyLabel
@onready var shop_list: ItemList   = $Panel/VBoxContainer/ShopList
@onready var qty_spinbox: SpinBox  = $Panel/VBoxContainer/QtyBox/QtySpinBox
@onready var price_label: Label    = $Panel/VBoxContainer/PriceLabel
@onready var buy_btn: Button       = $Panel/VBoxContainer/ButtonBox/BuyBtn
@onready var close_btn: Button     = $Panel/VBoxContainer/ButtonBox/CloseBtn

var _selected_item_id: String = ""


func _ready() -> void:
	buy_btn.pressed.connect(_on_buy_pressed)
	close_btn.pressed.connect(hide)
	shop_list.item_selected.connect(_on_item_selected)
	qty_spinbox.value_changed.connect(_on_qty_changed)
	ShopManager.purchase_failed.connect(_on_purchase_failed)
	ShopManager.purchase_success.connect(_on_purchase_success)
	Inventory.money_changed.connect(_update_money_label)
	hide()


func open_shop() -> void:
	_refresh()
	show()


func _refresh() -> void:
	_update_money_label(Inventory.money)
	shop_list.clear()
	_selected_item_id = ""
	price_label.text = ""
	buy_btn.disabled = true

	for entry in ShopManager.catalogue:
		var item := ItemRegistry.get_item(entry["item_id"])
		if item == null:
			continue
		var stock_txt := " (infini)" if entry["available"] == -1 else " (x" + str(entry["available"]) + ")"
		shop_list.add_item(item.item_name + stock_txt)
		shop_list.set_item_metadata(shop_list.item_count - 1, entry["item_id"])


func _update_money_label(amount: int) -> void:
	money_label.text = "Or : " + str(amount) + " pi"


func _on_item_selected(index: int) -> void:
	_selected_item_id = shop_list.get_item_metadata(index)
	buy_btn.disabled = false
	_update_price_label()


func _on_qty_changed(_val: float) -> void:
	_update_price_label()


func _update_price_label() -> void:
	if _selected_item_id == "":
		return
	var item := ItemRegistry.get_item(_selected_item_id)
	if item == null:
		return
	var qty := int(qty_spinbox.value)
	price_label.text = "Prix : " + str(item.buy_price * qty) + " pi"


func _on_buy_pressed() -> void:
	if _selected_item_id == "":
		return
	ShopManager.buy(_selected_item_id, int(qty_spinbox.value))


func _on_purchase_failed(reason: String) -> void:
	price_label.text = reason


func _on_purchase_success(item_id: String, quantity: int) -> void:
	var item := ItemRegistry.get_item(item_id)
	price_label.text = "Achete : " + item.item_name + " x" + str(quantity)
	_refresh()
