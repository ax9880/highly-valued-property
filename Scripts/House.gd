extends Node2D

export(String, "lo", "mid", "high") var price_range = "lo"

export(String, "moriya", "shining",
			"megumu", "mountain", "hatate",
			"aya", "momiji", "kutaka", "onsen",
			"sannyo", "dragon", "nitori", "toad",
			"tent", "takane", "hina", "kasen", "yamanba",
			"ropeway", "chimata", "aki", "ringo") var id

var status = HouseStatus.Ownership.not_owned
var listing_status = HouseStatus.Listing.listed


var delisted_color : Color = Color(0.5, 0.5, 0.5)
var listed_color = Color(0.9, 0.9, 0.9)
var highlighted_color = Color("ffffff")
var owned_color = Color("fbda00")

# Unix timestamp of last click
# To avoid double click issue
var click_time := 0

export var max_price = 950
export var min_price = 800

var minimum_reached_price = max_price
var maximum_reached_price = min_price

var current_price = 0
var base_price = 0
var price_amplitude = 0
var price_mid_point = 0

var previous_price = 0

export var time_modifier = 0.4
var current_time_modifier = time_modifier

var elapsed_time = 0

var extremum_count = 0
var extremum_flag = false
var proximity_percentage = 0.10

var high_price_nine_patch_texture = load("res://Assets/UI/gold_patch.png")
var mid_price_nine_patch_texture = load("res://Assets/UI/silver_patch.png")
var low_price_nine_patch_texture = load("res://Assets/UI/copper_patch.png")

onready var price_label = get_node("Label")
onready var arrow_sprite = get_node("Label/ArrowSprite")

onready var delisting_timer = get_node("DelistingTimer")
onready var tween = get_node("Tween")

signal house_clicked(id, status, current_price)
signal delisted(house)
signal bought(house)
signal mouse_on_house(id)

var func_ref : String
var price_func_ref

# -----------------------------------------------------------------------------#
# Built-in functions
# -----------------------------------------------------------------------------#

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	delist_house()
	
	price_amplitude = (max_price - min_price) / 2
	price_mid_point = _average(max_price, min_price)
	
	price_func_ref = funcref(self, "sine")
	
	base_price = rand_range(min_price, max_price)
	
	current_price = base_price


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if listing_status == HouseStatus.Listing.delisting:
		return
	
	_update_house_price(delta)
	
	price_label.text = "%4d" % current_price
	
	if previous_price > current_price:
		# Price has gone down
		arrow_sprite.frame = 0
	elif previous_price < current_price:
		# Price is going up
		arrow_sprite.frame = 1
	# if prices are the same, don't touch the arrow


# -----------------------------------------------------------------------------#
# Price function
# -----------------------------------------------------------------------------#
func _update_house_price(delta: float) -> void:
	elapsed_time += delta * current_time_modifier
	
	previous_price = current_price
	
	current_price = _price_function(elapsed_time, price_amplitude, base_price, price_mid_point)


func _price_function(time, amplitude, x_offset, y_offset) -> int:
	# A * sin(w * t) + b
	return int(amplitude * price_func_ref.call_func(time + x_offset) + y_offset)


func _average(a, b) -> float:
	return (a + b) / 2


# -----------------------------------------------------------------------------#
# Periodic functions for price_function
# -----------------------------------------------------------------------------#
func sine(x) -> float:
	return sin(x)


func cosine(x) -> float:
	return cos(x)
	

func minus_cosine(x) -> float:
	return -cos(x)
	

func sine_dot_cosine(x) -> float:
	return sin(x) * cos(x)
	
	
func sine_2(x) -> float:
	return 0.5 * (sin(x) + sin(x/2))
	
	
func sine_3(x) -> float:
	return  0.3 * (sin(x) + sin(2*x) + sin(3*x))


# -----------------------------------------------------------------------------#
# Signals
# -----------------------------------------------------------------------------#
func _on_Area2D_input_event(_viewport, event, _shape_idx) -> void:
	if not is_listed():
		return
	
	if event is InputEventMouseButton and event.pressed:
		# Comparing it to the exact millisecond seems too tight, but
		# it works fine in this case
		# I'm unsure why this happens
		# It happens with both mouse pad and regular mouse
		if OS.get_ticks_msec() == click_time:
			return
		
		print("[House]: Clicked! Current price is: " + String(current_price))
		
		emit_signal("house_clicked", id, status, current_price)
		
		click_time = OS.get_ticks_msec()


func _execute_order(house_id, order, profit = 0) -> void:
	if not is_listed():
		return
	
	if(id != house_id):
		return
		
	# Should Player be the one that knows what they own ?
	# Yes, but maybe House should know the ID of its owner
	# That way I can add another player
	if order == HouseStatus.Order.buy:
		print("[House]: Bought house")
		
		_buy_house()
	elif order == HouseStatus.Order.sell: 
		print("[House]: Sold house")
		
		_sell_house(profit)

# -----------------------------------------------------------------------------#
# Buying and selling
# -----------------------------------------------------------------------------#
func _buy_house() -> void:
	$Sprite.modulate = owned_color
	
	$Sounds/SoundBuy.play()
	
	$Label/CurrencySprite.show()
		
	status = HouseStatus.Ownership.owned
	
	delisting_timer.stop()
	
	tween.stop(self, "current_time_modifier")
	
	# TODO: tween time back to default
	current_time_modifier = time_modifier
	
	emit_signal("bought", self)


func _sell_house(profit) -> void:
	$Sprite.modulate = highlighted_color
	
	status = HouseStatus.Ownership.not_owned
	
	$Label/ArrowSprite.hide()
	
	var text = ""
	
	if profit >= 0:
		$Sounds/SoundSellProfit.play()
		text = "+%4d" % profit
	else:
		$Sounds/SoundSellLoss.play()
		text = "%4d" % profit
	
	$Label.text = text
	
	listing_status = HouseStatus.Listing.delisting
	
	$Tween.interpolate_property($Label, "modulate",
			null, Color(1, 1, 1, 0), 2,
			Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$Tween.start()
	
	delist_house()

# -----------------------------------------------------------------------------#
# Listing and delisting
# -----------------------------------------------------------------------------#
func is_listed() -> bool:
	return listing_status == HouseStatus.Listing.listed


func list_house() -> void:
	if randf() < 0.5:
		func_ref = "sine"
	else:
		func_ref = "cosine"
		
	price_func_ref = funcref(self, func_ref)
	
	var nine_patch_texture
	
	if price_range == "lo":
		nine_patch_texture = low_price_nine_patch_texture
	elif price_range == "mid":
		nine_patch_texture = mid_price_nine_patch_texture
	else:
		nine_patch_texture = high_price_nine_patch_texture
	
	$Label/NinePatchRect.texture = nine_patch_texture
	
	self.modulate = listed_color
	
	$Label/ArrowSprite.show()
	$Label.modulate = Color("ffffff")
	$Label.show()
	
	$Sounds/SoundListHi.play()
	
	listing_status = HouseStatus.Listing.listed
	
	delisting_timer.start()
	
	base_price = 0
	elapsed_time = elapsed_time * randf()
	
	set_process(true)


func delist_house() -> void:
	if listing_status != HouseStatus.Listing.delisting:
		$Label.hide()
		listing_status = HouseStatus.Listing.not_listed
		self.modulate = delisted_color
	else:
		$Sprite.modulate = delisted_color
	
	current_time_modifier = time_modifier
	
	emit_signal("delisted", self)
	
	set_process(false)

# -----------------------------------------------------------------------------#
# Automatic delisting
# -----------------------------------------------------------------------------#

func _on_DelistingTimer_timeout() -> void:
	tween.interpolate_property(self, "current_time_modifier",
			null, 0, 2,
			Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	
	tween.start()


func _on_Tween_tween_completed(_object: Object, key: String) -> void:
	if key == ":current_time_modifier":
		delist_house()
		$Sounds/SoundDelistHi.play()
	elif key == ":modulate":
		listing_status = HouseStatus.Listing.not_listed
		$Label/CurrencySprite.hide()

# -----------------------------------------------------------------------------#
# Disabling node
# -----------------------------------------------------------------------------#
func disable() -> void:
	$DelistingTimer.set_paused(true)
	set_process(false)

# -----------------------------------------------------------------------------#
# House highlighting
# -----------------------------------------------------------------------------#
# Highlights a house to show that you can buy or sell it
func _on_Area2D_mouse_entered() -> void:
	emit_signal("mouse_on_house", id)
	
	if listing_status == HouseStatus.Listing.not_listed:
		return
	
	if status != HouseStatus.Ownership.owned:
		self.modulate = highlighted_color


# Resets house color to normal one after the mouse has left its general area
func _on_Area2D_mouse_exited() -> void:
	if listing_status == HouseStatus.Listing.not_listed:
		return
	
	if status != HouseStatus.Ownership.owned:
		self.modulate = listed_color
