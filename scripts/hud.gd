
extends CanvasLayer

@onready var hpbar: ProgressBar = $HUD/ProgressBar
@onready var hptxt: Label = $HUD/HPTEXT
@onready var ammostat: Label = $HUD/ammostat

const HEALTH_GREEN := Color.GREEN
const HEALTH_YELLOW := Color.YELLOW
const HEALTH_RED := Color.RED


func hpupdate(hpnow: int) -> void:
	hpbar.value = hpnow
	hptxt.text = str(hpnow)

	var health_percent := clampf(float(hpnow) / 100.0, 0.0, 1.0)
	var bar_color: Color

	if health_percent >= 0.5:
		bar_color = HEALTH_YELLOW.lerp(
			HEALTH_GREEN,
			(health_percent - 0.5) / 0.5
		)
	else:
		bar_color = HEALTH_RED.lerp(
			HEALTH_YELLOW,
			health_percent / 0.5
		)

	var fill_style = hpbar.get_theme_stylebox("fill").duplicate()
	fill_style.bg_color = bar_color
	hpbar.add_theme_stylebox_override("fill", fill_style)


func ammoupdate(mag: int, reserve: int) -> void:
	ammostat.text = str(mag) + "/" + str(reserve)


func _ready() -> void:
	hpbar.max_value = 100
	hpupdate(100)
