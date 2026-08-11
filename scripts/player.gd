extends CharacterBody3D
class_name Player

@export var mouse_sensitivity: float = 0.002
@export var base_speed: float = 5.0
@export var walk_speed: float = 2.5
@export var crouch_speed: float = 2.0
@export var jump_velocity: float = 4.5
@export var crouch_height: float = 1.0
@export var stand_height: float = 1.8

@export var weapon_model_path: String = "res://assets/models/low-poly_stg_44.glb"
@export var weapon_scale: float = 0.5
@export var weapon_rotation: Vector3 = Vector3(0, PI, 0)

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var weapon_holder: Node3D = $Head/Camera3D/WeaponHolder
@onready var standing_collision: CollisionShape3D = $StandingCollision
@onready var crouching_collision: CollisionShape3D = $CrouchingCollision
@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D

var current_speed: float = base_speed
var is_crouching: bool = false

# Weapon state
var can_shoot: bool = true
var current_ammo: int = 30
var reserve_ammo: int = 90
const MAGAZINE_SIZE: int = 30
const FIRE_RATE: float = 0.1
const RELOAD_TIME: float = 2.0
const DAMAGE: int = 25
const SPREAD: float = 0.02
const WEAPON_RANGE: float = 100.0
var is_reloading: bool = false

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    crouching_collision.disabled = true
    standing_collision.disabled = false
    _load_weapon_model()

func _load_weapon_model() -> void:
    var scene := load(weapon_model_path) as PackedScene
    if scene == null:
        push_warning("Failed to load weapon model: " + weapon_model_path)
        _create_debug_weapon()
        return
    
    var weapon := scene.instantiate() as Node3D
    if weapon == null:
        push_warning("Weapon model is not a Node3D")
        _create_debug_weapon()
        return
    
    print("Weapon loaded: ", weapon.name, " with ", weapon.get_child_count(), " children")
    
    weapon.scale = Vector3(weapon_scale, weapon_scale, weapon_scale)
    weapon.rotation = weapon_rotation
    
    for child in weapon_holder.get_children():
        child.queue_free()
    
    weapon_holder.add_child(weapon)
    print("Weapon placed at holder: pos=", weapon_holder.position, " scale=", weapon_scale)

func _create_debug_weapon() -> void:
    var mesh := BoxMesh.new()
    mesh.size = Vector3(0.1, 0.1, 0.3)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(1, 0, 0)
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mesh.material = mat
    
    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    
    for child in weapon_holder.get_children():
        child.queue_free()
    weapon_holder.add_child(mi)
    print("DEBUG: red placeholder box shown at weapon holder")

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

    if event.is_action_pressed("shoot"):
        _try_shoot()
    if event.is_action_pressed("reload"):
        _try_reload()

func _physics_process(delta: float) -> void:
    _handle_crouch(delta)
    _handle_movement(delta)
    move_and_slide()

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

func _handle_crouch(delta: float) -> void:
    if Input.is_action_pressed("crouch"):
        if not is_crouching:
            is_crouching = true
            standing_collision.disabled = true
            crouching_collision.disabled = false
            camera.position.y = crouch_height * 0.8
    else:
        if is_crouching:
            is_crouching = false
            standing_collision.disabled = false
            crouching_collision.disabled = true
            camera.position.y = stand_height * 0.9

func _try_shoot() -> void:
    if not can_shoot or is_reloading or current_ammo <= 0:
        return

    current_ammo -= 1
    can_shoot = false
    get_tree().create_timer(FIRE_RATE).timeout.connect(func(): can_shoot = true)

    weapon_holder.position.z += 0.02
    get_tree().create_timer(0.05).timeout.connect(func(): weapon_holder.position.z -= 0.02)

    raycast.force_raycast_update()
    if raycast.is_colliding():
        var collider := raycast.get_collider()
        var hit_point := raycast.get_collision_point()
        print("Hit: ", collider.name, " at ", hit_point)

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

func get_ammo_text() -> String:
    return "%d / %d" % [current_ammo, reserve_ammo]
