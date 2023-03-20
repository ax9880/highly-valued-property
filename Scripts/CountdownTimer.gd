extends Node2D


func _process(_delta):
	var time_left = $Timer.time_left
	
	var minutes = int(time_left/60)
	var seconds = int(time_left) % 60
	
	# Time left: 59:59
	$TimeLeftLabel.text = "%s:\n%02d:%02d" % [tr("TIME_LEFT"), minutes, seconds]
