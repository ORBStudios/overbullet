extends CanvasLayer

@onready var hpbar = $HUD/ProgressBar
@onready var hptxt = $HUD/HPTEXT
@onready var ammostat = $HUD/ammostat

func hpupdate(hpnow:int):
	hpbar.value = hpnow
	hptxt.text = str(hpnow)
	
func  ammoupdate(mag:int,reserve:int):
	ammostat.text = str(mag)+"/"+str(reserve)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hpbar.value = 100
	hptxt.text = "100"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
