class_name RecipeData
extends Resource

enum ItemType { INGREDIENT, TOOL, COOKED, MISC }

@export var name: String = ""
@export var description: String = ""
@export var required_temp: int = 180
@export var temp_tolerance: int = 20
@export var required_time: float = 30.0
@export var burn_delay: float = 15.0
@export var result_item: String = ""
@export var burnt_item: String = "Plat brule"
@export var unlocked_by_default: bool = false

# Cle = item_id, Valeur = quantite requise
# Ex: {"pate_pain": 1, "oeuf": 2}
@export var required_ingredients: Dictionary = {}
