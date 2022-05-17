# List F1,F2 for series of sounds
#
# Matthias K. Franken, 2022

form Input
	real numFormants 5
	real maxFormant 5500
	comment Time window start and end to measure formant values
	real vwlOnset 0.15
	real vwlOffset 0.20
endform

n = numberOfSelected("Sound")
for i from 1 to n
	sound'i' = selected("Sound", i)
endfor

clearinfo


for i from 1 to n
	selectObject: sound'i'
	name$ = selected$("Sound")
	fm = To Formant (burg): 0, numFormants, maxFormant, 0.025, 50
	f1 = Get mean: 1, vwlOnset, vwlOffset, "hertz"
	f2 = Get mean: 2, vwlOnset, vwlOffset, "hertz"

	appendInfoLine: name$, tab$, round(f1), " Hz", tab$, round(f2), " Hz"
	selectObject: fm
	Remove
endfor
