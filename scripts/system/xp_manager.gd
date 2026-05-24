extends Node

signal xp_gained(amount: int, new_total: int)
signal level_up(new_level: int)

var current_xp: int = 0
var current_level: int = 1


func _ready() -> void:
    print("XPManager OK")


func xp_to_next_level() -> int:
    return current_level * 100


func add_xp(amount: int) -> void:
    current_xp += amount
    xp_gained.emit(amount, current_xp)
    while current_xp >= xp_to_next_level():
        current_xp -= xp_to_next_level()
        current_level += 1
        level_up.emit(current_level)
        var hud = _get_hud()
        if hud:
            hud.show_notification("Niveau " + str(current_level) + " atteint !")


func _get_hud():
    var scene = get_tree().current_scene
    return scene.get_node_or_null("HUD") if scene else null


func to_dict() -> Dictionary:
    return {"xp": current_xp, "level": current_level}


func from_dict(data: Dictionary) -> void:
    current_xp    = int(data.get("xp", 0))
    current_level = int(data.get("level", 1))
    xp_gained.emit(0, current_xp)
