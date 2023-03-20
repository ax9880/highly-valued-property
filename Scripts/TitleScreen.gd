extends Node2D

# Option button item indices
var language_en_index = 0
var language_es_index = 1


# Called when the node enters the scene tree for the first time.
func _ready():
	if TranslationServer.get_locale() == "en":
		$Control/LanguageOptions.select(language_en_index)
	elif TranslationServer.get_locale() == "es":
		$Control/LanguageOptions.select(language_es_index)

func _on_StartButton_pressed():
	$Control/StartButton.disconnect("pressed", self, "_on_StartButton_pressed")
	
	$Tween.interpolate_property($Music/SongStart, "volume_db",
			null, -80, 0.5,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	
	$Music/ClickEffect.play()


func _on_QuitButton_pressed():
	get_tree().quit()


func _on_Tween_tween_completed(_object, _key):
	if get_tree().change_scene("res://Scenes/Level.tscn") != OK:
		print("Failed to change scene")


func _on_LanguageButton_pressed():
	TranslationServer.set_locale("en")


func _on_LanguageOptions_item_selected(index):
	if index == language_en_index:
		TranslationServer.set_locale("en")
	elif index == language_es_index:
		TranslationServer.set_locale("es")
	else:
		print("Unknown language option")
