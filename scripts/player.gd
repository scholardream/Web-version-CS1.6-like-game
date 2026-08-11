extends CharacterBody3D
class_name Player

signal health_changed(current: int, maximum: int)
signal ammo_changed(magazine: int, reserve: int)
signal hit_landed
signal died

@export var mouse_sensitivity: float = 0.002
@export var base_speed: float = 5.0
@export var walk_speed: float = 2.5
@export var crouch_speed: float = 2.0
@export var jump_velocity: float = 4.5
@export var crouch_transition_speed: float = 10.0

@export var max_health: int = 100

@export var weapon_model_path: String = "res://assets/models/low-poly_stg_44.glb"
@export var weapon_scale: float = 0.0008
@export var weapon_rotation: Vector3 = Vector3(0, PI / 2, 0)
@export var weapon_position: Vector3 = Vector3(0.0, -0.05, 0.0)

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var weapon_holder: Node3D = $Head/Camera3D/WeaponHolder
@onready var standing_collision: CollisionShape3D = $StandingCollision
@onready var crouching_collision: CollisionShape3D = $CrouchingCollision
@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D

const HEAD_STAND_Y: float = 1.6
const HEAD_CROUCH_Y: float = 1.0

var current_speed: float = base_speed
var is_crouching: bool = false
var target_head_height: float = HEAD_STAND_Y

# Health
var current_health: int
var spawn_position: Vector3

# Weapon state
var current_ammo: int = 30
var reserve_ammo: int = 90
const MAGAZINE_SIZE: int = 30
const FIRE_RATE: float = 0.1
const RELOAD_TIME: float = 2.0
const DAMAGE: int = 25
const HEADSHOT_MULTIPLIER: float = 2.0
const WEAPON_RANGE: float = 100.0
var is_reloading: bool = false

# Spread bloom: grows per shot, recovers over time.
const BASE_SPREAD: float = 0.004
const MAX_SPREAD: float = 0.045
const SPREAD_PER_SHOT: float = 0.006
const SPREAD_RECOVERY: float = 0.08  # radians per second
var current_spread: float = BASE_SPREAD
var fire_cooldown: float = 0.0


func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    crouching_collision.disabled = true
    standing_collision.disabled = false
    current_health = max_health
    spawn_position = global_position
    _load_weapon_model()


func _load_weapon_model() -> void:
    for child in weapon_holder.get_children():
        child.queue_free()

    if not ResourceLoader.exists(weapon_model_path):
        push_warning("Weapon model missing, using placeholder: " + weapon_model_path)
        weapon_holder.add_child(_make_placeholder_weapon())
        return

    var scene := load(weapon_model_path) as PackedScene
    var weapon := scene.instantiate() as Node3D if scene else null
    if weapon == null:
        push_warning("Weapon model is not a Node3D, using placeholder")
        weapon_holder.add_child(_make_placeholder_weapon())
        return

    weapon.scale = Vector3(weapon_scale, weapon_scale, weapon_scale)
    weapon.rotation = weapon_rotation
    weapon.position = weapon_position
    _strip_bundled_scene_nodes(weapon)
    weapon_holder.add_child(weapon)


func _strip_bundled_scene_nodes(root: Node) -> void:
    # Sketchfab exports often bundle their preview Camera and Light;
    # those would hijack the view / lighting, so remove them.
    for node in root.find_children("*", "", true, false):
        if node is Camera3D or node is Light3D:
            node.queue_free()


func _make_placeholder_weapon() -> MeshInstance3D:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = "PlaceholderWeapon"
    var box := BoxMesh.new()
    box.size = Vector3(0.08, 0.14, 0.6)
    mesh_instance.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.12, 0.12, 0.14)
    mesh_instance.material_override = material
    mesh_instance.position = Vector3(0.0, -0.05, -0.2)
    return mesh_instance


func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)
        head.rotate_x(-event.relative.y * mouse_sensitivity)
        head.rotation.x = clamp(head.rotation.x, -PI / 2.0, PI / 2.0)

    if event.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

    if event is InputEventMouseButton and event.pressed:
        if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

    if event.is_action_pressed("reload"):
        _try_reload()


func _process(delta: float) -> void:
    head.position.y = lerpf(head.position.y, target_head_height, crouch_transition_speed * delta)


func _physics_process(delta: float) -> void:
    fire_cooldown = maxf(fire_cooldown - delta, 0.0)
    current_spread = move_toward(current_spread, BASE_SPREAD, SPREAD_RECOVERY * delta)
    _handle_crouch()
    _handle_movement(delta)
    _handle_trigger()
    move_and_slide()


func _handle_trigger() -> void:
    if not Input.is_action_pressed("shoot"):
        return
    if current_ammo <= 0 and not is_reloading:
        _try_reload()
        return
    if fire_cooldown <= 0.0:
        _try_shoot()


func _handle_movement(delta: float) -> void:
    if not is_on_floor():
        velocity += get_gravity() * delta

    if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
        velocity.y = jump_velocity

    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

    if Input.is_action_pressed("walk"):
        current_speed = walk_speed
    elif is_crouching:
        current_speed = crouch_speed
    else:
        current_speed = base_speed

    if direction:
        velocity.x = direction.x * current_speed
        velocity.z = direction.z * current_speed
    else:
        velocity.x = move_toward(velocity.x, 0, current_speed)
        velocity.z = move_toward(velocity.z, 0, current_speed)


func _handle_crouch() -> void:
    if Input.is_action_pressed("crouch"):
        _set_crouched(true)
    elif is_crouching and _can_stand():
        _set_crouched(false)


func _set_crouched(value: bool) -> void:
    if is_crouching == value:
        return
    is_crouching = value
    standing_collision.disabled = value
    crouching_collision.disabled = not value
    target_head_height = HEAD_CROUCH_Y if value else HEAD_STAND_Y


func _can_stand() -> bool:
    # Make sure there is room for the standing capsule above us.
    var params := PhysicsShapeQueryParameters3D.new()
    params.shape = standing_collision.shape
    params.transform = standing_collision.global_transform
    params.transform.origin += Vector3.UP * 0.05
    params.exclude = [get_rid()]
    params.collision_mask = collision_mask
    return get_world_3d().direct_space_state.intersect_shape(params).is_empty()


func _try_shoot() -> void:
    if is_reloading or current_ammo <= 0:
        return

    current_ammo -= 1
    fire_cooldown = FIRE_RATE
    current_spread = minf(current_spread + _spread_modifier(), MAX_SPREAD)
    ammo_changed.emit(current_ammo, reserve_ammo)

    # Visual recoil on weapon holder
    weapon_holder.position.z += 0.02
    get_tree().create_timer(0.05).timeout.connect(func(): weapon_holder.position.z -= 0.02)

    # Raycast shoot with spread applied as a random cone offset
    raycast.rotation.x = randf_range(-current_spread, current_spread)
    raycast.rotation.y = randf_range(-current_spread, current_spread)
    raycast.force_raycast_update()

    if raycast.is_colliding():
        var collider := raycast.get_collider()
        if collider and collider.has_method("take_damage"):
            var damage := DAMAGE
            if collider.name.to_lower().contains("head"):
                damage = int(damage * HEADSHOT_MULTIPLIER)
            collider.take_damage(damage, self)
            hit_landed.emit()

    raycast.rotation = Vector3.ZERO


func _spread_modifier() -> float:
    # Standing still and crouching tightens spread; moving/airborne opens it up.
    var modifier := SPREAD_PER_SHOT
    if is_crouching or Input.is_action_pressed("walk"):
        modifier *= 0.6
    if not is_on_floor():
        modifier *= 2.0
    return modifier


func _try_reload() -> void:
    if is_reloading or current_ammo == MAGAZINE_SIZE or reserve_ammo <= 0:
        return
    is_reloading = true
    get_tree().create_timer(RELOAD_TIME).timeout.connect(_finish_reload)


func _finish_reload() -> void:
    var needed := MAGAZINE_SIZE - current_ammo
    var available := mini(needed, reserve_ammo)
    current_ammo += available
    reserve_ammo -= available
    is_reloading = false
    ammo_changed.emit(current_ammo, reserve_ammo)


func take_damage(amount: int, _from: Node = null) -> void:
    if current_health <= 0:
        return
    current_health = maxi(current_health - amount, 0)
    health_changed.emit(current_health, max_health)
    if current_health == 0:
        _die()


func _die() -> void:
    died.emit()
    _respawn()


func _respawn() -> void:
    global_position = spawn_position
    velocity = Vector3.ZERO
    current_health = max_health
    current_ammo = MAGAZINE_SIZE
    reserve_ammo = 90
    is_reloading = false
    health_changed.emit(current_health, max_health)
    ammo_changed.emit(current_ammo, reserve_ammo)


func get_ammo_text() -> String:
    return "%d / %d" % [current_ammo, reserve_ammo]
