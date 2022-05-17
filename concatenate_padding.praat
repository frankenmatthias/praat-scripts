# Concatenate sounds with zero padding in between
#
# Matthias K Franken, 2021

form Input
	comment Duration of padding in seconds
	positive duration 0.5
	comment Add padding before first sound?
	boolean silence_start 1
	comment Add padding after last sound?
	boolean silence_end 1
endform

n = numberOfSelected("Sound")

for i from 1 to n
	sound'i' = selected("Sound", i)
endfor

selectObject: sound1
fs = Get sampling frequency
nchan = Get number of channels

# create silences and copy sounds
sil0 = Create Sound from formula: "zero", nchan, 0, duration, fs, "0"
for j from 1 to n
	selectObject: sound'j'
	newsound'j' = Copy: "soundcopy"
	sil'j' = Create Sound from formula: "zero", nchan, 0, duration, fs, "0"
endfor

# select sounds
if silence_start
	selectObject: sil0
else
	selectObject: newsound1
endif

for j from 1 to n-1
	plusObject: newsound'j', sil'j'
endfor

plusObject: newsound'n'

if silence_end
	plusObject: sil'n'
endif

# concatenate
result = Concatenate
Rename: "chain_result"

# select copied sounds and silences to remove
selectObject: sil0
for j from 1 to n
	plusObject: newsound'j', sil'j'
endfor

if silence_end
	plusObject: sil'n'
endif
Remove
