extends Node2D

export var current_money = 15

# <string, int (house price at moment of purchase)>
var owned_houses : Dictionary = {}

signal execute_order(id, order, profit)


func _on_house_click(id, _status, current_price):
	print("[Player]: House clicked! " + id)
	
	print("[Player]: Owned houses: ")
	print(owned_houses)
	
	if (owned_houses.has(id)):
		var profit = current_price - owned_houses[id]
		
		current_money += current_price
		
		if !owned_houses.erase(id):
			# Should not happen, in theory
			# This is just to remove the warning for unused return value
			print("[Player]: Tried to sell/remove unowned house")
		
		emit_signal("execute_order", id, HouseStatus.Order.sell, profit)
		
		print("[Player]: Sold " + id)
	else:
		if(current_money > current_price):
			current_money -= current_price
			
			owned_houses[id] = current_price
			
			emit_signal("execute_order", id, HouseStatus.Order.buy)

		else:
			# Can't buy
			# Play sound
			$Sounds/CannotBuySound.play()
		
	print("[Player]: Money: " + String(current_money))
