extends CanvasLayer

@onready var health_bar: ProgressBar        = $HealthBar
@onready var xp_bar: ProgressBar            = $XPBar
@onready var level_label: Label             = $LevelLabel
@onready var money_label: Label             = $MoneyLabel
@onready var notification_panel: Panel      = $NotificationPanel
@onready var notification_label: Label      = $NotificationPanel/NotificationLabel

var max_hp: int = 100
var current_hp: int = 100


func _ready() -> void:
    notification_panel.hide()
    _update_health_bar()
    XPManager.xp_gained.connect(_on_xp_gained)
    XPManager.level_up.connect(_on_level_up)
    Inventory.money_changed.connect(_on_money_changed)
    _refresh_xp()
    _on_money_changed(Inventory.money)


func set_health(value: int) -> void:
    current_hp = clamp(value, 0, max_hp)
    _update_health_bar()


func show_notification(message: String, duration: float = 3.0) -> void:
    notification_label.text = message
    notification_panel.show()
    await get_tree().create_timer(duration).timeout
    notification_panel.hide()


func _update_health_bar() -> void:
    health_bar.max_value = max_hp
    health_bar.value     = current_hp


func _refresh_xp() -> void:
    xp_bar.max_value = XPManager.xp_to_next_level()
    xp_bar.value     = XPManager.current_xp
    level_label.text = "Nv." + str(XPManager.current_level)


func _on_xp_gained(_amount: int, _total: int) -> void:
    _refresh_xp()


func _on_level_up(new_level: int) -> void:
    level_label.text = "Nv." + str(new_level)
    _refresh_xp()


func _on_money_changed(amount: int) -> void:
    money_label.text = str(amount) + " pi"
