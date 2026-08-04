extends CharacterBody3D
class_name Player

@export var mouse_sensitivity: float = 0.002
@export var base_speed: float = 5.0
@export var walk_speed: float = 2.5
@export var crouch_speed: float = 2.0
@export var jump_velocity: float = 4.5
@export var crouch_height: float = 1.0
@export var stand_height: float = 1.8

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var standing_collision: CollisionShape3D = $StandingCollision
@onready var crouching_collision: CollisionShape3D = $CrouchingCollision
@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D

var current_speed: float = base_speed
var is_crouching: bool = false

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    crouching_collision.disabled = true
    standing_collision.disabled = false

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

    # Speed modifiers
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
        # TODO: check headroom before standing up
        if is_crouching:
            is_crouching = false
            standing_collision.disabled = false
            crouching_collision.disabled = true
            camera.position.y = stand_height * 0.9

func get_camera() -> Camera3D:
    return camera
