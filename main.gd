extends Node2D

var csound: CsoundGodot
var csound_instance: CsoundGodot

@onready
var synth_player: AudioStreamPlayer = $SynthPlayer

@export var midi_file: Resource


func _ready():
	CsoundServer.connect("csound_layout_changed", csound_layout_changed)
	CsoundServer.connect("csound_ready", csound_ready)

	var csound_layout: CsoundLayout = ResourceLoader.load("res://multiple_csound_instances_layout.tres")
	CsoundServer.set_csound_layout(csound_layout)


func csound_layout_changed():
	csound = CsoundServer.get_csound("Main")
	csound.send_control_channel("cutoff", 1)

	synth_player.stream.set_csound_name("simple_synth")


func csound_ready(csound_name):
	if csound_name == "Main":
		add_csound_instance()

	if csound_name == "simple_synth":
		compile_synth_csd(csound_name)


func compile_synth_csd(csound_name):
	var csound_synth: CsoundGodot = CsoundServer.get_csound(csound_name)

	csound_synth.compile_csd("""
<CsoundSynthesizer>
<CsInstruments>
instr 1
  print p4, p5
  kenv linseg 0, 1, 1, 2, 0
  a1 oscil p5 * kenv, p4, 1
  outs a1, a1
endin
</CsInstruments>
<CsScore>
f 1 0 16384 10 1
f 0 3600
i 1 1 3 440 0.5
</CsScore>
</CsoundSynthesizer>
""")


func add_csound_instance():
	CsoundServer.add_csound()
	var csound_index = CsoundServer.get_csound_count() -1

	var csound_instance_name = "csound_instance"
	CsoundServer.set_csound_name(csound_index, csound_instance_name)

	csound_instance = CsoundServer.get_csound(csound_instance_name)

	csound_instance.call_deferred("initialize")
	csound_instance.csound_ready.connect(csound_instance_ready)


func csound_instance_ready(csound_name):
	if csound_name != "csound_instance":
		return

	var audio_stream_csound: AudioStreamCsound = AudioStreamCsound.new()
	audio_stream_csound.set_csound_name(csound_name)

	var audio_stream_player: AudioStreamPlayer = AudioStreamPlayer.new()
	audio_stream_player.stream = audio_stream_csound
	audio_stream_player.volume_db = -20

	add_child(audio_stream_player)

	audio_stream_player.play()

	print ("csound is ready")

	csound_instance.compile_csd("""
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
	print (csound_instance.evaluate_code('return 2 + 2'))

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
	csound_instance.event_string(message)


func send_key_off(chan: int, key: int):
	var message: String = 'i"buzz_instrument" 0 0 {chan} {key} 0'.format({"chan": chan, "key": key})
	csound_instance.event_string(message)


func send_note_on(chan: int, note_name: String, velocity: int):
	var message: String = 'i "buzz_instrument2" 0 -1 {chan} "{note_name}" {velocity}'.format({"chan": chan, "note_name": note_name, "velocity": velocity})
	csound_instance.event_string(message)


func send_note_off(chan: int, note_name: String):
	var message: String = 'i "buzz_instrument2" 0 0 {chan} "{note_name}" 0'.format({"chan": chan, "note_name": note_name})
	csound_instance.event_string(message)


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
