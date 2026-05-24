extends CharacterBody2D

# Animations : idle / walk_down / walk_up / walk_left / walk_right

@export var speed: float = 150.0

signal interacted(area: Area2D)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea

var _direction: Vector2 = Vector2.DOWN


func _physics_process(_delta: float) -> void:
	_handle_movement()
	_handle_animation()
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()


func _handle_movement() -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed
	if input_dir != Vector2.ZERO:
		_direction = input_dir


func _handle_animation() -> void:
	if velocity == Vector2.ZERO:
		_play("idle")
	else:
		_play("walk_" + _get_direction_name())


func _play(anim: String) -> void:
	if animated_sprite.animation != anim:
		animated_sprite.play(anim)


func _get_direction_name() -> String:
	if abs(_direction.x) > abs(_direction.y):
		return "right" if _direction.x > 0 else "left"
	else:
		return "down" if _direction.y > 0 else "up"


func _try_interact() -> void:
	var overlapping := interaction_area.get_overlapping_areas()
	if overlapping.is_empty():
		return
	interacted.emit(overlapping[0])
