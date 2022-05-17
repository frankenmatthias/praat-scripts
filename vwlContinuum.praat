# Script to generate vowel continuum from source file
#
# Matthias K Franken, 2022

form Continuum input
comment The original sound should be selected before running the script.
positive nsteps 9
real f1step 10
real f2step -20
real vwlOnset 0.061364
real vwlOffset 0.321907
boolean correctRMS 1
boolean origSampleRate 1
boolean plotResult 1
boolean saveWAVs 1
sentence savedir continuum/
word continuumName HeadHad
endform

# write configuration to info window
appendInfoLine: "###"
appendInfoLine: date$()
appendInfoLine: " "
name$ = selected$("Sound")
appendInfoLine: "original: 'name$'"
appendInfoLine: "nsteps: 'nsteps'"
appendInfoLine: "f1step: 'f1step'"
appendInfoLine: "f2step: 'f2step'"
appendInfoLine: "vwlOnset: 'vwlOnset'"
appendInfoLine: "vwlOffset: 'vwlOffset'"
appendInfoLine: "correctRMS: 'correctRMS'"
appendInfoLine: "origSampleRate: 'origSampleRate'"

# Create folder to write results
savedir$ = "'savedir$''continuumName$'/"
createFolder: savedir$

# write configuration to text file
filename$ = "'savedir$''continuumName$'_config.txt"
writeFileLine: filename$, "###"
appendFileLine: filename$, date$()
appendFileLine: filename$, " "
appendFileLine: filename$, "original: 'name$'"
appendFileLine: filename$, "nsteps: 'nsteps'"
appendFileLine: filename$, "f1step: 'f1step'"
appendFileLine: filename$, "f2step: 'f2step'"
appendFileLine: filename$, "vwlOnset: 'vwlOnset'"
appendFileLine: filename$, "vwlOffset: 'vwlOffset'"
appendFileLine: filename$, "correctRMS: 'correctRMS'"
appendFileLine: filename$, "origSampleRate: 'origSampleRate'"

orig = selected("Sound")
sr = Get sampling frequency
appendInfoLine: "Original SR: 'sr'"
appendFileLine: filename$, "Original SR: 'sr'"
# resampling necessary because LPC finds formants up to Nyquist Freq
orig_resample = Resample: 11000, 50

# generate empty sound for zero-padding
pad1 = Create Sound from formula: "zero500", 1, 0, 0.5, 11000, "0"

# cut out vowel
selectObject: orig
onset = Get nearest zero crossing: 1, vwlOnset
offset = Get nearest zero crossing: 1, vwlOffset

selectObject: orig_resample
tg = To TextGrid: "a1", ""
selectObject: tg
Insert boundary: 1, onset
Insert boundary: 1, offset

selectObject: orig_resample, tg
Extract all intervals: 1, "no"
n = numberOfSelected("Sound")
for i from 1 to n
	sound'i' = selected("Sound", i)
endfor

# vwl length and rms
selectObject: sound2
dur = Get total duration
rmso = Get root-mean-square: 0, 0

# pad vowel
selectObject: pad1
pad2 = Copy: "pad2"
selectObject: pad1, sound2, pad2
sound2_padded = Concatenate
tg_padding = To TextGrid: "a1", ""
Insert boundary: 1, 0.5
Insert boundary: 1, 'dur'+0.5
Set interval text: 1, 2, "v"

# get source sound
selectObject: sound2_padded
orig_lpc = To LPC (burg): 16, 0.025, 0.005, 50
selectObject: sound2_padded, orig_lpc
src = Filter (inverse)

# get original Formant tracks for later manipulation
selectObject: sound2_padded
fm = To Formant (burg): 0, 5, 5500, 0.025, 50
fg = Down to FormantGrid

for i from 0 to nsteps
	selectObject: fg

	if i > 0
		# shift formants
		Formula (frequencies): "if row = 1 then self + 'f1step' else self fi"
		Formula (frequencies): "if row = 2 then self + 'f2step' else self fi"
	endif

	# apply new formant to source sound and remove padding
	selectObject: src, fg
	result = Filter
	selectObject: result, tg_padding
	result'i'_unpad = Extract intervals where: 1, "no", "is equal to", "v"

	# Correct changes in RMS
	if correctRMS
		rmsnow = Get root-mean-square: 0, 0
		Formula: "self * 'rmso' / 'rmsnow'"
	endif
	Rename: "step'i'"

	selectObject: result
	Remove
endfor


# concatenate pieces, resample back to original sr
selectObject: sound3
sound3_cpy = Copy: "lastpart"
selectObject: orig_resample
step0_final1 = Copy: "Step0"
for i from 0 to nsteps
	selectObject: sound1, result'i'_unpad, sound3_cpy
	if origSampleRate
		foo = Concatenate
		step'i'_final = Resample: sr, 50
		Rename: "Step'i'"
		selectObject: foo
		Remove
	else
		step'i'_final = Concatenate
		Rename: "Step'i'"
	endif

	# save results as WAV file
	if saveWAVs
		selectObject: step'i'_final
		sname$ = selected$("Sound")
		Save as WAV file: "'savedir$''continuumName$'_'sname$'.wav"
	endif

	selectObject: result'i'_unpad
	Remove
endfor

# Clean up praat window
selectObject: fm, fg, orig_lpc, sound1, sound2, sound3, tg, tg_padding, sound2_padded, orig_resample, pad1, pad2, sound3_cpy
Remove


# get resulting formant values
appendInfoLine: "###"
appendInfoLine: "Name",tab$,"F1[Hz]",tab$,"F2[Hz]",tab$,"Intensity[dB]"
appendFileLine: filename$, "###"
appendFileLine: filename$, "Name",tab$,"F1[Hz]",tab$,"F2[Hz]",tab$,"Intensity[dB]"
selectObject: step0_final1
for i from 0 to nsteps
	plusObject: step'i'_final
endfor

n = numberOfSelected("Sound")
for i from 1 to n
	sound'i' = selected("Sound", i)
endfor


lastf1 = 0
for i from 1 to n
	selectObject: sound'i'
	int = Get intensity (dB)
	name$ = selected$("Sound")
	fm = To Formant (burg): 0, 5, 5500, 0.025, 50
	f1 = Get mean: 1, onset, offset, "hertz"
	f2 = Get mean: 2, onset, offset, "hertz"
	d = 'f1' - 'lastf1'
	appendInfoLine: name$,tab$,round(f1),tab$,tab$,round(f2), tab$,fixed$(int, 2)
	appendFileLine: filename$, name$,tab$,round(f1),tab$,round(f2), tab$,fixed$(int, 2)
	selectObject: fm
	if plotResult
		if i > 1
			Colour: {i/n,0,1-i/n}
			Draw tracks: 0, 0, 2200, "yes"
		else
			Colour: {0,0,0}
			Draw tracks: 0, 0, 2200, "no"
		endif
	endif
	Remove
	lastf1 = f1
endfor

appendInfoLine: "###"
appendFileLine: filename$, "###"
