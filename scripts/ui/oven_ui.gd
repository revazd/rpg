extends CanvasLayer

# UI du four

var oven: Node = null  # référence au four

@onready var recipe_list: ItemList = $Panel/VBoxContainer/RecipeList
@onready var desc_label: Label = $Panel/VBoxContainer/DescLabel
@onready var temp_spinbox: SpinBox = $Panel/VBoxContainer/TempBox/TempSpinBox
@onready var time_label: Label = $Panel/VBoxContainer/TimeBox/TimeLabel
@onready var start_btn: Button = $Panel/VBoxContainer/ButtonBox/StartBtn
@onready var close_btn: Button = $Panel/VBoxContainer/ButtonBox/CloseBtn

var _selected_recipe: RecipeData = null


func _ready() -> void:
	start_btn.pressed.connect(_on_start_pressed)
	close_btn.pressed.connect(_on_close_pressed)
	recipe_list.item_selected.connect(_on_recipe_selected)

	temp_spinbox.min_value = 100
	temp_spinbox.max_value = 300
	temp_spinbox.step = 10
	temp_spinbox.value = 180


func refresh_recipes() -> void:
	recipe_list.clear()
	_selected_recipe = null

	desc_label.text = "Sélectionne une recette."
	time_label.text = "---"
	start_btn.disabled = true

	var unlocked: Array = RecipeManager.unlocked_recipes

	if unlocked.is_empty():
		recipe_list.add_item("Aucune recette débloquée")
		return

	for recipe in unlocked:
		if recipe is RecipeData:
			recipe_list.add_item(recipe.item_name)
		else:
			push_error("Élément invalide dans unlocked_recipes")


func _on_recipe_selected(index: int) -> void:
	var unlocked: Array = RecipeManager.unlocked_recipes

	if index < 0 or index >= unlocked.size():
		return

	var data = unlocked[index]

	if not (data is RecipeData):
		push_error("Recette invalide à l'index: " + str(index))
		return

	var recipe: RecipeData = data

	_selected_recipe = recipe

	desc_label.text = recipe.description
	time_label.text = str(int(recipe.required_time)) + " sec"
	temp_spinbox.value = recipe.required_temp

	start_btn.disabled = false


func _on_start_pressed() -> void:
	if _selected_recipe == null or oven == null:
		return

	var temp: int = int(temp_spinbox.value)
	oven.start_cooking(_selected_recipe, temp)

	hide()


func _on_close_pressed() -> void:
	if oven != null:
		oven.toggle_door()
	hide()
