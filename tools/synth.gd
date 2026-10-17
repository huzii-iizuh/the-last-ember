extends RefCounted
## Synthesises every sound in the game. tools/bake.gd writes them to audio/*.wav.

const RATE := 22050


static func all() -> Dictionary:
	# partials: [start Hz, end Hz, amplitude]
	return {
		"jump": make(0.14, [[320, 640, 0.5]], 0.0, 0.005),
		"land": make(0.10, [[120, 60, 0.4]], 0.5, 0.002),
		"pulse": make(0.7, [[880, 220, 0.3], [1320, 330, 0.12], [440, 110, 0.3]], 0.05, 0.01),
		"pulse_end": make(0.3, [[260, 420, 0.3]], 0.0, 0.01),
		"reveal": make(0.6, [[523, 523, 0.2], [784, 784, 0.15]], 0.02, 0.02),
		"checkpoint": make(1.3, [[660, 660, 0.3], [990, 990, 0.2], [1320, 1320, 0.1]], 0.0, 0.01),
		"death": make(0.7, [[420, 50, 0.45]], 0.35, 0.005),
		"click": make(0.06, [[900, 700, 0.3]], 0.0, 0.002),
		"beacon": make(5.5, [[130.8, 130.8, 0.25], [261.6, 261.6, 0.25], [329.6, 329.6, 0.2],
				[392.0, 392.0, 0.2], [523.3, 523.3, 0.12]], 0.0, 1.8, 0.8),
		"ambient": ambient(),
		"warm": warm_pad(),
	}


static func make(dur: float, partials: Array, noise: float, attack: float, decay := 2.0) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phases := []
	phases.resize(partials.size())
	phases.fill(0.0)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := t / dur
		var env := minf(t / attack, 1.0) * pow(1.0 - k, decay)
		var s := 0.0
		for j in partials.size():
			var pr = partials[j]
			phases[j] += TAU * lerpf(pr[0], pr[1], k) / RATE
			s += sin(phases[j]) * pr[2]
		if noise > 0.0:
			lp += (randf_range(-1.0, 1.0) - lp) * 0.3
			s += lp * noise
		data.encode_s16(i * 2, int(clampf(s * env, -1.0, 1.0) * 32000.0))
	return wav(data)


# 8-second loops. Every frequency completes a whole number of cycles in 8 s, so they loop cleanly.
static func ambient() -> AudioStreamWAV:
	var n := 8 * RATE
	var data := PackedByteArray()
	data.resize(n * 2)
	var wind := 0.0
	var crackle := 0.0
	for i in n:
		var t := float(i) / RATE
		var s := sin(TAU * 55.0 * t) * 0.16 + sin(TAU * 82.5 * t) * 0.08
		s += sin(TAU * 110.0 * t) * 0.05 * (0.5 + 0.5 * sin(TAU * 0.125 * t))
		wind += (randf_range(-1.0, 1.0) - wind) * 0.02
		s += wind * 0.9 * (0.6 + 0.4 * sin(TAU * 0.25 * t))
		if randf() < 0.0004:
			crackle = 1.0
		crackle *= 0.994
		s += randf_range(-1.0, 1.0) * crackle * 0.12
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32000.0))
	return wav(data)


# A warm major pad that fades in as the Ember nears the lighthouse.
static func warm_pad() -> AudioStreamWAV:
	var n := 8 * RATE
	var data := PackedByteArray()
	data.resize(n * 2)
	var notes := [[130.75, 0.16], [196.0, 0.12], [261.5, 0.12], [329.625, 0.09], [392.0, 0.07], [523.0, 0.04]]
	for i in n:
		var t := float(i) / RATE
		var s := 0.0
		for j in notes.size():
			var swell := 0.7 + 0.3 * sin(TAU * 0.125 * t + j)
			s += sin(TAU * notes[j][0] * t) * notes[j][1] * swell
		s += sin(TAU * 784.0 * t) * 0.02 * (0.5 + 0.5 * sin(TAU * 0.25 * t))
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32000.0))
	return wav(data)


static func wav(data: PackedByteArray) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	return w
