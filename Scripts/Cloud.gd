extends Node2D

export var tween_time = 30
export var timer_jitter = 5

export var min_y = 32 + 8
export var max_y = 180

export var start_x = -48
export var end_x = 400

var frame = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	start_movement()


func _on_Tween_tween_completed(_object, _key):
	start_movement()


func start_movement():
	$Sprite.frame = rand_range(0, 7)
	
	self.position = Vector2(start_x, rand_range(min_y, max_y))
	
	$Tween.interpolate_property(self, "position",
			null, Vector2(end_x, position.y), tween_time + rand_range(-timer_jitter, timer_jitter),
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
