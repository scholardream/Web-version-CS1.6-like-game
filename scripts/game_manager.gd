extends Node
class_name GameManager

enum GameState { MENU, BUY, PLAYING, END_ROUND, GAME_OVER }

var current_state: GameState = GameState.PLAYING
var round_time: float = 120.0
var score_team_a: int = 0
var score_team_b: int = 0

@onready var round_timer: Timer = $RoundTimer
@onready var hud: Control = $HUD
@onready var crosshair: Label = $HUD/Crosshair
@onready var ammo_label: Label = $HUD/AmmoLabel
@onready var health_label: Label = $HUD/HealthLabel
@onready var player: Player = $"../Player"


func _ready() -> void:
    # Player is a sibling node; its _ready() runs first, so we can both
    # connect signals and initialize the HUD from its current state.
    player.health_changed.connect(_on_player_health_changed)
    player.ammo_changed.connect(_on_player_ammo_changed)
    player.hit_landed.connect(_on_player_hit_landed)
    _on_player_health_changed(player.current_health, player.max_health)
    _on_player_ammo_changed(player.current_ammo, player.reserve_ammo)
    start_round()


func start_round() -> void:
    current_state = GameState.PLAYING
    round_time = 120.0
    round_timer.start(1.0)


func _on_round_timer_timeout() -> void:
    if current_state == GameState.PLAYING:
        round_time -= 1.0
        if round_time <= 0:
            end_round()


func end_round() -> void:
    current_state = GameState.END_ROUND
    # TODO: determine winner, update scores, show scoreboard
    round_timer.stop()


func add_score(team: String) -> void:
    if team == "a":
        score_team_a += 1
    else:
        score_team_b += 1


func _on_player_health_changed(current: int, _maximum: int) -> void:
    health_label.text = "HP: %d" % current


func _on_player_ammo_changed(magazine: int, reserve: int) -> void:
    ammo_label.text = "%d / %d" % [magazine, reserve]


func _on_player_hit_landed() -> void:
    crosshair.modulate = Color(1.0, 0.25, 0.25)
    var tween := create_tween()
    tween.tween_property(crosshair, "modulate", Color.WHITE, 0.15)
