extends CanvasLayer

@onready var q_label : Label = $VBoxContainer/QLabel
@onready var w_label : Label = $VBoxContainer/WLabel
@onready var e_label : Label = $VBoxContainer/ELabel
@onready var r_label : Label = $VBoxContainer/RLabel

var q_cooldown = 0.0
var w_cooldown = 0.0
var e_cooldown = 0.0
var r_cooldown = 0.0

func _process(delta):
	if q_cooldown > 0:
		q_cooldown = max(0, q_cooldown - delta)
	if w_cooldown > 0:
		w_cooldown = max(0, w_cooldown - delta)
	if e_cooldown > 0:
		e_cooldown = max(0, e_cooldown - delta)
	if r_cooldown > 0:
		r_cooldown = max(0, r_cooldown - delta)
	
	q_label.text = "Q: " + (str(snapped(q_cooldown, 0.1)) + "s" if q_cooldown > 0 else "Ready")
	w_label.text = "W: " + (str(snapped(w_cooldown, 0.1)) + "s" if w_cooldown > 0 else "Ready")
	e_label.text = "E: " + (str(snapped(e_cooldown, 0.1)) + "s" if e_cooldown > 0 else "Ready")
	r_label.text = "R: " + (str(snapped(r_cooldown, 0.1)) + "s" if r_cooldown > 0 else "Ready")

func set_q_cooldown(time: float):
	q_cooldown = time

func set_w_cooldown(time: float):
	w_cooldown = time

func set_e_cooldown(time: float):
	e_cooldown = time

func set_r_cooldown(time: float):
	r_cooldown = time
