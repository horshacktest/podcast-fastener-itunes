property oggfolder : "/Users/jeff/Music/toOggplayer/"
property outfolder : "/Users/jeff/Music/Fastened/"
property outputformat : "mp3"

on run
	--do shell script "env"
	--do shell script "echo $user"
	--do shell script "echo $PATH"
	-- NEED TO GET /usr/local/bin in $PATH do shell script is not run in an interactive shell and env set by .profile is not available
	checkcmd("sox")
	set thesox to "/usr/local/bin/sox" --checkcmd("sox")
	set theogg to "/usr/local/bin/oggenc" --checkcmd("oggenc")
	set thelame to "/opt/local/bin/lame" --checkcmd("oggenc")
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
			--vvv I am skipping the intermediate wav format an compressing straight to mp3
			--my compress(fPOSIX, fmetadata)
		end repeat
	end tell
end run

on checkcmd(avar)
	do shell script "pwd;which " & avar
end checkcmd

on fast(f)
	--/usr/local/bin/sox "{}" -t wav "{}.wav" stretch 0.5 100
	--/usr/local/bin/sox "{}" -t wav "{}.wav" tempo 1.8
	global thesox, fn
	-- set thesoxcmd to thesox & " " & f & " -t .wav " & quoted form of (oggfolder & fn & ".wav") & " stretch 0.6 100"
	set thesoxcmd to thesox & " " & f & " -t ." & outputformat & " " & quoted form of (oggfolder & fn & "." & outputformat) & " tempo 1.8 30"
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

------=====================================================---------------------------

on fastPipe(fPOSIX)
	global thesox, fn
	set thesoxcmd to thesox & " " & fPOSIX & " - tempo 1.8 30"
	do shell script thesoxcmd & " | " & compressOgg(fPOSIX, fmetadata) & " &"
	--log thesoxcmd
end fastPipe

on compressOgg(f, m)
	--oggenc -q 1 --downmix --resample 16000 "{}.wav" -o "{}.ogg"
	set theoggcmd to theogg & " -q 1 --downmix --resample 16000 -t " & (quoted form of n of m) & Â
		" -a " & (quoted form of art of m) & " -l " & (quoted form of alb of m) & Â
		" - -o " & quoted form of (outfolder & fn & ".ogg") & " &> " & quoted form of (outfolder & "error")
	--log theoggcmd
end compressOgg

on compressLame(f, m)
	set thelamecmd to thelame & " -B 64 --tt " & (quoted form of n of m) & Â
		" --ta " & (quoted form of art of m) & " --tl " & (quoted form of alb of m) & Â
		" - " & quoted form of (outfolder & fn & ".mp3")
	--log theoggcmd
end compressLame



(*
New sox 14.0.1 deprecates stretch, and new command and going to mp3 in one command is
sox "080222soil.mp3" "080222soil-FAST.mp3" tempo 2 30
*)


