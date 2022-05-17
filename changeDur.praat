# change duration of a sound file using PSOLA
#
# Matthias K Franken, 2022

form changeDur
  comment The original sound should be selected before running the script.
  comment If not relative, duration should be in seconds.
  real newDuration 1.0
  boolean relative 1
endform

orig = selected("Sound")
orig$ = selected$("Sound")
sr = Get sampling frequency
orig_dur = Get total duration

if relative
  target_dur = newDuration * orig_dur
else
  target_dur = newDuration
endif

# padding
pad1 = Create Sound from formula: "zero500", 1, 0, 0.5, sr, "0"
selectObject: orig
orig_copy = Copy: "orig_copy"
selectObject: pad1
pad2 = Copy: "pad2"
selectObject: pad1, orig_copy, pad2
orig_padded = Concatenate

# manipulation
selectObject: orig_padded
manip = To Manipulation: 0.01, 75.0, 600.0
durTier = Extract duration tier

selectObject: durTier
Add point: 0.5*(orig_dur+1.0), target_dur / orig_dur

selectObject: manip, durTier
Replace duration tier

selectObject: manip
result_padded = Get resynthesis (overlap-add)

# unpad
padDur = 0.5 * (target_dur / orig_dur)
selectObject: result_padded
tg = To TextGrid: "a1", ""
Insert boundary: 1, padDur
Insert boundary: 1, padDur+target_dur
Set interval text: 1, 2, "sound"

selectObject: result_padded, tg
result = Extract intervals where: 1, "no", "is equal to", "sound"
Rename: "'orig$'_dur"

# clean up
selectObject: pad1, orig_copy, pad2, orig_padded, manip, durTier, result_padded, tg
Remove
