property oggfolder : "/Users/jeff/Music/toOggplayer/"

on run
	set thesox to checkcmd("sox")
	set theogg to checkcmd("oggenc")
	tell application "iTunes"
		set selectedTracks to selection
		repeat with f in selectedTracks
			set fmetadata to {art:(artist of f), n:(name of f), alb:(album of f)}
			set fl to location of f
			set fPOSIX to quoted form of POSIX path of fl
			log fPOSIX
			tell application "Finder"
				set text item delimiters of AppleScript to "."
				set fn to text items 1 through -2 of (name of fl as string) as string
				set text item delimiters of AppleScript to ""
			end tell
			my fast(fPOSIX)
			my compress(fPOSIX, fmetadata)
		end repeat
	end tell
end run

on checkcmd(avar)
	do shell script "which " & avar
end checkcmd

on fast(f)
	--~/bin/sox "{}" -t wav "{}.wav" stretch 0.5 100
	global thesox, fn
	set thesoxcmd to thesox & " " & f & " -t .wav " & quoted form of (oggfolder & fn & ".wav") & " stretch 0.6 100"
	do shell script thesoxcmd
	--log thesoxcmd
end fast

on compress(f, m)
	--oggenc -q 1 --downmix --resample 16000 "{}.wav" -o "{}.ogg"
	global theogg, fn
	set theoggcmd to theogg & " -q 1 --downmix --resample 16000 -t " & Â
		(quoted form of n of m) & " -a " & (quoted form of art of m) & " -l " & (quoted form of alb of m) & Â
		" " & quoted form of (oggfolder & fn & ".wav") & " -o " & quoted form of (oggfolder & fn & ".ogg") & " &> " & quoted form of (oggfolder & "error") & "  &"
	--log theoggcmd
	do shell script theoggcmd
end compress
