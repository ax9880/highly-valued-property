extends Control

var on_color : Color = Color(1, 1, 1)
var off_color : Color = Color(0.5, 0.5, 0.5)

var sfx_bus = "SoundEffects"
var music_bus = "Master" # TODO: Move Music to a separate bus. This mutes SFX and music

func _ready():
	_toggle_sounds(Settings.sfx_on, $SfxButton, sfx_bus)
	_toggle_sounds(Settings.music_on, $MusicButton, music_bus)


func _on_SfxButton_pressed():
	Settings.sfx_on = !Settings.sfx_on
	
	_toggle_sounds(Settings.sfx_on, $SfxButton, sfx_bus)


func _on_MusicButton_pressed():
	Settings.music_on = !Settings.music_on
	
	_toggle_sounds(Settings.music_on, $MusicButton, music_bus)


func _toggle_sounds(enabled: bool, button: TextureButton, audio_bus_name: String) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(audio_bus_name), !enabled)
	
	#print("[Volume Control]: Bus %s, enabled: %s" % [audio_bus_name, enabled])
	
	if enabled:
		button.modulate = on_color
	else:
		button.modulate = off_color
