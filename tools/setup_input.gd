extends SceneTree
## Writes The Last Ember's controls into project.godot.
##   godot --headless --path . -s res://tools/setup_input.gd

func _init() -> void:
	var keys := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE, KEY_W, KEY_UP], "pulse": [KEY_Q],
		"pause": [KEY_ESCAPE], "restart": [KEY_R],
	}
	for action in keys:
		var events := []
		for k in keys[action]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			e.device = -1
			events.append(e)
		if action == "pulse":
			var m := InputEventMouseButton.new()
			m.button_index = MOUSE_BUTTON_RIGHT
			m.device = -1
			events.append(m)
		ProjectSettings.set_setting("input/" + action, {"deadzone": 0.2, "events": events})
	ProjectSettings.save()
	print("INPUT OK")
	quit()
