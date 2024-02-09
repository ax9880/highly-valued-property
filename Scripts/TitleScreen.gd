extends Node2D

# Option button item indices
var language_en_index = 0
var language_es_index = 1


func _ready() -> void:
	if TranslationServer.get_locale() == "en":
		$Control/LanguageOptions.select(language_en_index)
	elif TranslationServer.get_locale().begins_with("es"):
		$Control/LanguageOptions.select(language_es_index)
	
	if OS.get_name() == "HTML5":
		$Control/QuitButton.hide()


func _on_StartButton_pressed() -> void:
	$Control/StartButton.disconnect("pressed", self, "_on_StartButton_pressed")
	
	$Tween.interpolate_property($Music/SongStart, "volume_db",
			null, -80, 0.5,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	
	$Music/ClickEffect.play()


func _on_QuitButton_pressed() -> void:
	get_tree().quit()


func _on_Tween_tween_completed(_object: Object, _key: String) -> void:
	if get_tree().change_scene("res://Scenes/Level.tscn") != OK:
		print("Failed to change scene")


func _on_LanguageButton_pressed() -> void:
	TranslationServer.set_locale("en")


func _on_LanguageOptions_item_selected(index):
	if index == language_en_index:
		TranslationServer.set_locale("en")
	elif index == language_es_index:
		TranslationServer.set_locale("es")
	else:
		print("Unknown language option")
