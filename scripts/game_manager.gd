extends Node
class_name GameManager

enum GameState { MENU, BUY, PLAYING, END_ROUND, GAME_OVER }

var current_state: GameState = GameState.PLAYING
var round_time: float = 120.0
var score_team_a: int = 0
var score_team_b: int = 0

@onready var round_timer: Timer = $RoundTimer
@onready var hud: Control = $HUD

func _ready() -> void:
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
