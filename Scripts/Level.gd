extends Node2D

# Dictionary
var house_names_dict = {
	"moriya": "HOUSE_MORIYA",  "shining": "HOUSE_SHINING", 
	"megumu": "HOUSE_MEGUMU",  "mountain": "HOUSE_MOUNTAIN",  "hatate": "HOUSE_HATATE", 
	"aya": "HOUSE_AYA",  "momiji": "HOUSE_MOMIJI",  "kutaka": "HOUSE_KUTAKA",
	"onsen": "HOUSE_ONSEN",
	"sannyo": "HOUSE_SANNYO",  "dragon": "HOUSE_DRAGON", 
	"nitori": "HOUSE_NITORI",  "toad": "HOUSE_TOAD", 
	"tent": "HOUSE_TENT",  "takane": "HOUSE_TAKANE",
	"hina": "HOUSE_HINA",  "kasen": "HOUSE_KASEN",  "yamanba": "HOUSE_YAMANBA", 
	"ropeway": "HOUSE_ROPEWAY",  "chimata": "HOUSE_CHIMATA",
	"aki": "HOUSE_AKI",  "ringo": "HOUSE_RINGO"
}

# Kinda backwards, but 7 - 4 -> 4 active houses at most ??? Check
export var low_queue_minimum_size = 4

var low_price_range_queue : Array = []
var mid_price_range_queue : Array = []
var high_price_range_queue : Array = []

var LOW_PRICE_RANGE_GROUP = "lo"
var MID_PRICE_RANGE_GROUP = "mid"
var HIGH_PRICE_RANGE_GROUP = "high"

onready var low_timer_wait_time = $Timers/LoTimer.wait_time
onready var mid_timer_wait_time = $Timers/MidTimer.wait_time
onready var high_timer_wait_time = $Timers/HighTimer.wait_time

onready var player = $Player
onready var player_money_label: Label = $Control/Money

var delay_timer_threshold = 1.5
var timer_jitter = 2
var on_buy_jitter = [0.55, 0.75]

var time_start = 0
var time_now = 0

var all_houses = []
var assets = 0


# -----------------------------------------------------------------------------#
# Initialization
# -----------------------------------------------------------------------------#
func _ready():
	randomize()
	
	for mountain_floor in $Floors.get_children():
		var mountain_floor_children = mountain_floor.get_children()
		
		for house in mountain_floor_children:
			all_houses.append(house)
	
	populate_queues(all_houses)
	
	# Order is important! Mountain should not be in any listing queue
	all_houses.append($Mountain/ForSale)
	
	_connect_house_signals(all_houses)
	
	low_price_range_queue.shuffle()
	mid_price_range_queue.shuffle()
	high_price_range_queue.shuffle()
	
	$Control/HouseNameLabel.text = ""
	
	time_start = OS.get_unix_time()
	

# $NodeThatEmitsSignal.connect("signal_name", $NodeThatWillReceiveSignal, "method_of_node_that_will_receive_signal")
func _connect_house_signals(houses: Array) -> void:
	for house in houses:
		house.connect("house_clicked", player, "_on_house_click")
		house.connect("delisted", self, "_on_house_delisted")
		house.connect("bought", self, "_on_house_bought")
		house.connect("mouse_on_house", self, "_on_mouse_house_hover")
		
		player.connect("execute_order", house, "_execute_order")


func _disconnect_house_signals(houses: Array) -> void:
	for house in houses:
		house.disconnect("house_clicked", player, "_on_house_click")


# -----------------------------------------------------------------------------#
# Process
# -----------------------------------------------------------------------------#
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	player_money_label.set_text("%s:\n%4d" % [tr("MONEY"), player.current_money])


func _on_mouse_house_hover(id: String):
	$Control/HouseNameLabel.text = house_names_dict[id]


# -----------------------------------------------------------------------------#
# Win condition
# -----------------------------------------------------------------------------#
func _on_player_buy_mountain():
	_pause_game_loop()
	
	assets = _get_player_assets()
	
	print("[Level]: Bought the Mountain!")
	$Sounds/BuyMountain.play()
	
	# Fade out music
	$Tween.interpolate_property($Sounds/BgMusicPlayer, "volume_db",
			null, -80, 0.5,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			
	$Tween.start()


func _pause_game_loop():
	# Play sound
	# Fade out music
	# Disable nodes
	# Pause timers
	# After timer is done, wait 1 second
	# TODO:
	# x Disconnect all signals
	# transition to next scene?
	$Control/CountdownTimer/Timer.set_paused(true)
	
	# Pause timers
	for timer in $Timers.get_children():
		timer.set_paused(true)
	
	# Disable mountain and house nodes so the price doesn't change
	# and so that the player can't buy them
	$Player.set_process(false)
	
	# Disconnect signals so the player can't buy houses
	_disconnect_house_signals(all_houses)
	
	for house in all_houses:
		house.disable()


# -----------------------------------------------------------------------------#
# House listing
# -----------------------------------------------------------------------------#
func populate_queues(houses: Array) -> void:
	for house in houses:
		add_house_to_queue(house)


func add_house_to_queue(house, shuffle : bool = false):
	var queue : Array
	
	if house.price_range == LOW_PRICE_RANGE_GROUP:
		queue = low_price_range_queue
	elif house.price_range == MID_PRICE_RANGE_GROUP:
		queue = mid_price_range_queue
	elif house.price_range == HIGH_PRICE_RANGE_GROUP:
		queue = high_price_range_queue
	else:
		print("[Level]: Unknown price range")
		return
		
	queue.push_back(house)
	
	if shuffle:
		queue.shuffle()
		
		if queue.front() == house:
			# Don't repeat the house we just delisted
			# Move it to the back if it ends up in front
			queue.push_back(queue.pop_front())


func _on_action_delay_timers(_price_range : String):
	# Used to delay the timers that belonged to the other groups
	# Now it just delays all timers
	delay_other_timers($Timers.get_children())


func _on_house_bought(house):
	_on_action_delay_timers(house.price_range)
	
	if house.id == "mountain":
		_on_player_buy_mountain()


func _on_house_delisted(house):
	add_house_to_queue(house, true)
	
	_on_action_delay_timers(house.price_range)


func _on_LoTimer_timeout():
	list_enqueued_house(low_price_range_queue, low_queue_minimum_size,
		$Timers/LoTimer, low_timer_wait_time, [$Timers/HighTimer, $Timers/MidTimer])


func _on_MidTimer_timeout():
	list_enqueued_house(mid_price_range_queue, low_queue_minimum_size,
		$Timers/MidTimer, mid_timer_wait_time, [$Timers/HighTimer, $Timers/LoTimer])


func _on_HighTimer_timeout() -> void:
	list_enqueued_house(high_price_range_queue, low_queue_minimum_size,
		$Timers/HighTimer, high_timer_wait_time, [$Timers/MidTimer, $Timers/LoTimer])


func list_enqueued_house(queue : Array, size : int, timer : Timer, default_wait_time : float, delayed_timers : Array):
	if queue.size()  > size:
		var house = queue.pop_front()
		
		house.list_house()
		
		timer.start(default_wait_time + rand_range(-timer_jitter, timer_jitter))
		
		delay_other_timers(delayed_timers)


# Delay other timers after a house is listed, delisted or sold so that a new house
# doesn't appear right away and the sounds overlap or anything
# It also feels a bit smoother and cleaner when there is some space between
# any house listing or delisting
func delay_other_timers(delayed_timers : Array) -> void:
	for t in delayed_timers:
		if t.time_left != 0 and t.time_left < delay_timer_threshold:
			t.start(t.time_left + rand_range(on_buy_jitter[0], on_buy_jitter[1]))


func _on_MountainTimer_timeout() -> void:
	$Mountain/ForSale.list_house()
	
	# Stop this timer so the Mountain is never delisted
	$Mountain/ForSale/DelistingTimer.stop()


func _on_Tween_tween_all_completed() -> void:
	# We are not tweening the engine time scale anymore, so we could check the
	# property here
	# Currently we are only tweening the background music
	_show_score_screen()


# Win score screen
func _show_score_screen():
	$Control/ScoreUI/Win/NumberText/Assets.text = str(assets)
	$Control/ScoreUI/Win/NumberText/Money.text = str($Player.current_money)
	$Control/ScoreUI/Win/NumberText/Total.text = str($Player.current_money + assets)
	
	var time_elapsed = $Control/CountdownTimer/Timer.wait_time - $Control/CountdownTimer/Timer.time_left
	
	# TODO: Make utility function
	var minutes = int(time_elapsed/60)
	
	# Ceiling because int() acts like floor()
	# In the label, we show the time with floor()
	# So if we show the remaining time with floor() too, then we may be missing
	# an extra second and it might confuse the player
	var seconds = int(ceil(time_elapsed)) % 60
	
	$Control/ScoreUI/Win/NumberText/Time.text = "%02d:%02d" % [minutes, seconds]
	
	$Control/ScoreUI/Win.show()
	$Control/ScoreUI.show()


func _get_player_assets() -> int:
	var owned_houses = $Player.owned_houses
	
	# Sum of the current price of all houses owned by the player
	var sum = 0
	
	for house in all_houses:
		if house.id in owned_houses:
			sum += house.current_price
	
	return sum


func _on_BackButton_pressed() -> void:
	var return_code = get_tree().change_scene("res://Scenes/TitleScreen.tscn")
	
	if return_code != OK:
		print("[Level]: Failed to change scene")


func _on_CountdownTimer_timeout() -> void:
	_pause_game_loop()
	
	# TODO: Tween?
	$Sounds/BgMusicPlayer.stop()
	$Sounds/GameOver.play()
	
	$Control/ScoreUI/GameOver.show()
	
	$Control/ScoreUI.show()
