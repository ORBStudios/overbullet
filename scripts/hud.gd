extends CanvasLayer

@onready var hpbar = $ProgressBar
func hpupdate(hpnow:int):
	hpbar.value = hpnow
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hpbar.value = 100


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
