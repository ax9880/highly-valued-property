extends Control

const SFX_BUS := "SoundEffects"
const MUSIC_BUS := "Music" # TODO: Move Music to a separate bus. This mutes SFX and music


var on_color : Color = Color(1, 1, 1)
var off_color : Color = Color(0.5, 0.5, 0.5)


func _ready() -> void:
	_toggle_sounds(Settings.sfx_on, $SfxButton, SFX_BUS)
	_toggle_sounds(Settings.music_on, $MusicButton, MUSIC_BUS)


func _on_SfxButton_pressed() -> void:
	Settings.sfx_on = !Settings.sfx_on
	
	_toggle_sounds(Settings.sfx_on, $SfxButton, SFX_BUS)


func _on_MusicButton_pressed() -> void:
	Settings.music_on = !Settings.music_on
	
	_toggle_sounds(Settings.music_on, $MusicButton, MUSIC_BUS)


func _toggle_sounds(enabled: bool, button: TextureButton, audio_bus_name: String) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(audio_bus_name), !enabled)
	
	if enabled:
		button.modulate = on_color
	else:
		button.modulate = off_color
