class_name ItemData
extends Resource

enum ItemType { INGREDIENT, TOOL, COOKED, MISC }

@export var id: String = ""
@export var item_name: String = ""
@export var description: String = ""
@export var type: ItemType = ItemType.MISC
@export var icon: Texture2D = null
@export var max_stack: int = 99
@export var is_tool: bool = false
@export var buy_price: int = 0
@export var sell_price: int = 0
