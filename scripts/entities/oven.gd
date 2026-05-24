extends Area2D
class_name Oven

signal cooking_finished(result_item: String)
signal cooking_burnt(burnt_item: String)

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var is_open: bool = false
var is_cooking: bool = false
var current_recipe: RecipeData = null
var chosen_temp: int = 0

var _ui_instance = null


func _ready() -> void:
	anim.play("closed")
	add_to_group("oven")


func interact() -> void:
	if is_cooking:
		_show_cooking_status()
		return
	
	toggle_door()


func toggle_door() -> void:
	is_open = !is_open

	if is_open:
		anim.play("open")
		_open_ui()
	else:
		anim.play("closed")
		_close_ui()


# ─────────────────────────────────────────────
# LANCEMENT CUISSON
# ─────────────────────────────────────────────

func start_cooking(recipe: RecipeData, temp: int) -> bool:

	if recipe == null:
		return false

	# Vérifie ingrédients
	for ingredient_id in recipe.required_ingredients:

		var qty: int = recipe.required_ingredients[ingredient_id]

		if !Inventory.has_item(ingredient_id, qty):

			var item = ItemRegistry.get_item(ingredient_id)
			var item_name: String = str(ingredient_id)

			if item:
				item_name = item.item_name

			if item:
				item_name = item.item_name

			_notify("Il te manque : %s x%d" % [item_name, qty])
			return false

	# Retire ingrédients
	for ingredient_id in recipe.required_ingredients:
		Inventory.remove_item(
			ingredient_id,
			recipe.required_ingredients[ingredient_id]
		)

	current_recipe = recipe
	chosen_temp = temp
	is_cooking = true
	is_open = false

	anim.play("cooking")
	_close_ui()

	var cook_timer := get_tree().create_timer(recipe.required_time)
	cook_timer.timeout.connect(_on_cooking_done)

	return true


func _on_cooking_done() -> void:

	if !is_cooking or current_recipe == null:
		return

	var temp_ok: bool = abs(
		chosen_temp - current_recipe.required_temp
	) <= current_recipe.temp_tolerance

	if !temp_ok:
		_trigger_burnt()
		return

	_notify("%s est prêt ! Viens le chercher." % current_recipe.item_name)

	cooking_finished.emit(current_recipe.result_item)

	Inventory.add_item(
		current_recipe.result_item.to_lower().replace(" ", "_"),
		1
	)

	var burn_timer := get_tree().create_timer(current_recipe.burn_delay)
	burn_timer.timeout.connect(_check_burnt)


func _check_burnt() -> void:

	if is_cooking:
		_trigger_burnt()


func _trigger_burnt() -> void:

	if !is_cooking or current_recipe == null:
		return

	is_cooking = false

	anim.play("closed")

	_notify("%s a brûlé ! Jette-le à la poubelle." % current_recipe.item_name)

	cooking_burnt.emit(current_recipe.burnt_item)

	var burnt_id := current_recipe.burnt_item.to_lower().replace(" ", "_")

	Inventory.add_item(burnt_id, 1)

	current_recipe = null


func collect_result() -> void:

	is_cooking = false
	current_recipe = null

	anim.play("closed")


func _notify(msg: String) -> void:

	var hud = get_tree().current_scene.get_node_or_null("HUD")

	if hud:
		hud.show_notification(msg)


# ─────────────────────────────────────────────
# UI
# ─────────────────────────────────────────────

func _open_ui() -> void:

	if _ui_instance == null:

		var scene = load("res://scenes/ui/OvenUI.tscn")

		if scene == null:
			push_error("Impossible de charger OvenUI.tscn")
			return

		_ui_instance = scene.instantiate()
		_ui_instance.oven = self

		get_tree().current_scene.add_child(_ui_instance)

	_ui_instance.show()

	if _ui_instance.has_method("refresh_recipes"):
		_ui_instance.refresh_recipes()


func _close_ui() -> void:

	if _ui_instance != null:
		_ui_instance.hide()


func _show_cooking_status() -> void:

	if current_recipe != null:
		_notify("Cuisson en cours : " + current_recipe.item_name)
