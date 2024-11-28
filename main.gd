extends Node2D

var csound: CsoundGodot

@export var midi_file: Resource


func _ready():
	CsoundServer.connect("csound_layout_changed", csound_layout_changed)


func csound_layout_changed():
	csound = CsoundServer.get_csound("Main")
	csound.send_control_channel("cutoff", 1)

	csound.csound_ready.connect(csound_ready)


func csound_ready(csound_name):
	print ("csound is ready")

	if csound_name != "Main":
		return

	csound.compile_orchestra("""
<CsoundSynthesizer>
<CsInstruments>

instr buzz_instrument

iFreq mtof p5
iAmp = p6 / 127
iFn  = 1

kSeg linsegr iAmp, .5, iAmp / 2, 1, 0

asig buzz 1, iFreq, kSeg * iAmp, iFn
outs asig, asig

endin

</CsInstruments>
<CsScore>
f 1 0 16384 10 1
</CsScore>
</CsoundSynthesizer>
""")

	await get_tree().create_timer(10.0).timeout

	send_note_on(3, 64, 64)
	send_note_on(3, 66, 64)

	await get_tree().create_timer(1.0).timeout

	send_note_on(3, 68, 64)

	await get_tree().create_timer(3.0).timeout

	send_note_off(3, 64)
	send_note_off(3, 66)
	send_note_off(3, 68)


func send_note_on(chan: int, key: int, velocity: int):
	var message: String = 'i"buzz_instrument" 0 -1 {chan} {key} {velocity}'.format({"chan": chan, "key": key, "velocity": velocity})
	csound.event_string(message)


func send_note_off(chan: int, key: int):
	var message: String = 'i"buzz_instrument" 0 {chan} 0 {key}'.format({"chan": chan, "key": key})
	csound.event_string(message)


func _process(_delta):
	pass


func _on_check_button_toggled(toggled_on: bool):
	if toggled_on:
		csound.note_on(0, 60, 90)
	else:
		csound.note_off(0, 60)


func _on_check_button_2_toggled(toggled_on: bool):
	if toggled_on:
		csound.note_on(1, 64, 90)
	else:
		csound.note_off(1, 64)


func _on_check_button_3_toggled(toggled_on: bool):
	if toggled_on:
		csound.note_on(2, 67, 90)
	else:
		csound.note_off(2, 67)


func _on_v_slider_value_changed(value: float):
	csound.send_control_channel("cutoff", value)


func _on_button_pressed():
	csound.play_midi(midi_file)
