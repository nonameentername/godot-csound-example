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
	if csound_name != "Main":
		return

	print ("csound is ready")

	csound.compile_csd("""
<CsoundSynthesizer>
<CsInstruments>

instr buzz_instrument

iChan = p4
iFreq mtof p5
iAmp = p6 / 127
iFn  = 1

kSeg linsegr iAmp, .5, iAmp / 2, 1, 0

asig buzz 1, iFreq, kSeg * iAmp, iFn
outs asig, asig

endin

instr buzz_instrument2

iChan = p4
SNote = p5
iFreq = ntof:i(SNote)
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
	print (csound.evaluate_code('return 2 + 2'))

	await get_tree().create_timer(10.0).timeout

	send_note_on(3, '4C', 64)

	await get_tree().create_timer(1.0).timeout

	send_key_on(3, 62, 64)

	await get_tree().create_timer(1.0).timeout

	send_key_on(3, 64, 64)

	await get_tree().create_timer(3.0).timeout

	send_note_off(3, '4C')
	send_key_off(3, 62)
	send_key_off(3, 64)


func send_key_on(chan: int, key: int, velocity: int):
	var message: String = 'i"buzz_instrument" 0 -1 {chan} {key} {velocity}'.format({"chan": chan, "key": key, "velocity": velocity})
	csound.event_string(message)


func send_key_off(chan: int, key: int):
	var message: String = 'i"buzz_instrument" 0 0 {chan} {key} 0'.format({"chan": chan, "key": key})
	csound.event_string(message)


func send_note_on(chan: int, note_name: String, velocity: int):
	var message: String = 'i "buzz_instrument2" 0 -1 {chan} "{note_name}" {velocity}'.format({"chan": chan, "note_name": note_name, "velocity": velocity})
	csound.event_string(message)


func send_note_off(chan: int, note_name: String):
	var message: String = 'i "buzz_instrument2" 0 0 {chan} "{note_name}" 0'.format({"chan": chan, "note_name": note_name})
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
