extends Node

signal recipe_unlocked(recipe: Dictionary)

var all_recipes: Array = []
var unlocked_recipes: Array = []


func _ready() -> void:
	print("RecipeManager OK")
	_load_default_recipes()


func _load_default_recipes() -> void:
	var pain := {
		"item_name": "Pain",
		"description": "Un pain dore. Necessite de la pate a pain.",
		"required_temp": 200, "temp_tolerance": 20,
		"required_time": 30.0, "burn_delay": 20.0,
		"result_item": "pain_cuit", "burnt_item": "pain_brule",
		"required_ingredients": {"pate_pain": 1},
		"unlocked_by_default": true
	}
	var gateau := {
		"item_name": "Gateau",
		"description": "Un gateau moelleux.",
		"required_temp": 170, "temp_tolerance": 15,
		"required_time": 50.0, "burn_delay": 15.0,
		"result_item": "gateau", "burnt_item": "gateau_brule",
		"required_ingredients": {"farine": 2, "oeuf": 2, "beurre": 1, "sucre": 1},
		"unlocked_by_default": false
	}
	var tarte := {
		"item_name": "Tarte aux pommes",
		"description": "Une tarte fondante.",
		"required_temp": 180, "temp_tolerance": 20,
		"required_time": 45.0, "burn_delay": 20.0,
		"result_item": "tarte_pommes", "burnt_item": "tarte_brulee",
		"required_ingredients": {"farine": 1, "beurre": 1, "pomme": 3},
		"unlocked_by_default": false
	}
	all_recipes = [pain, gateau, tarte]
	for r in all_recipes:
		if r["unlocked_by_default"]:
			unlocked_recipes.append(r)


func unlock_recipe(recipe_name: String) -> void:
	for r in all_recipes:
		if r["item_name"] == recipe_name and not unlocked_recipes.has(r):
			unlocked_recipes.append(r)
			recipe_unlocked.emit(r)
			return


func to_dict() -> Array:
	var result: Array = []
	for r in unlocked_recipes:
		result.append(r["item_name"])
	return result


func from_dict(names: Array) -> void:
	for n in names:
		unlock_recipe(n)
