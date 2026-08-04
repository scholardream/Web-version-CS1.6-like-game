extends Node3D
class_name Weapon

@export var weapon_name: String = "Rifle"
@export var damage: int = 25
@export var fire_rate: float = 0.1   # seconds between shots
@export var reload_time: float = 2.0
@export var magazine_size: int = 30
@export var max_ammo: int = 90
@export var spread: float = 0.02
@export var range_distance: float = 100.0

var current_ammo: int
var reserve_ammo: int
var can_shoot: bool = true
var is_reloading: bool = false

@onready var cooldown_timer: Timer = $CooldownTimer
@onready var reload_timer: Timer = $ReloadTimer

func _ready() -> void:
    current_ammo = magazine_size
    reserve_ammo = max_ammo

func shoot(from: Vector3, direction: Vector3) -> Dictionary:
    if not can_shoot or is_reloading or current_ammo <= 0:
        return {"hit": false}

    current_ammo -= 1
    can_shoot = false
    cooldown_timer.start(fire_rate)

    var spread_offset := Vector3(
        randf_range(-spread, spread),
        randf_range(-spread, spread),
        randf_range(-spread, spread)
    )
    var shot_dir := (direction + spread_offset).normalized()

    var space_state := get_world_3d().direct_space_state
    var query := PhysicsRayQueryParameters3D.new()
    query.from = from
    query.to = from + shot_dir * range_distance
    query.collision_mask = 1 | 2 | 3  # World, Player, Enemy

    var result := space_state.intersect_ray(query)

    if result:
        return {
            "hit": true,
            "position": result.position,
            "normal": result.normal,
            "collider": result.collider,
            "damage": damage
        }

    return {"hit": false}

func reload() -> void:
    if is_reloading or current_ammo == magazine_size or reserve_ammo <= 0:
        return

    is_reloading = true
    reload_timer.start(reload_time)

func _on_cooldown_timer_timeout() -> void:
    can_shoot = true

func _on_reload_timer_timeout() -> void:
    var needed := magazine_size - current_ammo
    var available := min(needed, reserve_ammo)
    current_ammo += available
    reserve_ammo -= available
    is_reloading = false

func get_ammo_text() -> String:
    return "%d / %d" % [current_ammo, reserve_ammo]
