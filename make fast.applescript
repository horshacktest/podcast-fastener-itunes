# notifications http://macosxautomation.com/mavericks/notifications/01.html

property outfolder : ""
property outputformat : "mp3"

property thesox : "/usr/local/bin/sox" --checkcmd("sox")
property thelame : "/usr/local/bin/lame" --checkcmd("lame")
--property theid3 : "/usr/local/bin/id3v2" --checkcmd("id3v2")
property theid3cp : "/usr/local/bin/id3cp" --checkcmd("id3v2")


on run
	-- NEED TO GET /usr/local/bin in $PATH. do shell script is not run in an interactive shell and env set by .profile is not available
	-- checkcmd("sox")
	tell application "iTunes"
		set selectedTracks to selection
		repeat with f in selectedTracks
			set genre of f to "Podcast"
			set fmetadata to {art:(artist of f), n:(name of f), alb:(album of f), comm:(comment of f)}
			set fl to location of f
			-- get fmetadata
			set fastreturn to my fastPipe(fl, fmetadata)
			do shell script theid3cp & " " & quoted form of POSIX path of fl & " " & quoted form of POSIX path of fastreturn
			set enabled of f to false
		end repeat
		
	end tell
end run

on checkcmd(avar)
	do shell script "pwd;which " & avar
end checkcmd

------=====================================================---------------------------

-- returns a file reference of the fastened track
on fastPipe(fl, fmetadata)
	set fPOSIX to quoted form of POSIX path of fl
	set outputfile to (outfolder & getFileBasename(fl) & "." & outputformat)
	set thesoxcmd to thesox & " " & fPOSIX & " -t .wav - compand 0.3,1 6:-70,-60,-20 -5 -90 0.2 tempo -s 1.5 dither "
	set thecompresscommand to compressLame(fl, fmetadata)
	do shell script thesoxcmd & " | " & thecompresscommand & " &"
	log thesoxcmd & " | " & thecompresscommand & " &"
	return POSIX file outputfile
end fastPipe



on getFileBasename(fl)
	tell application "Finder"
		set text item delimiters of AppleScript to "."
		set fn to text items 1 through -2 of (name of fl as string) as string
		set text item delimiters of AppleScript to ""
	end tell
	return fn
end getFileBasename

on compressLame(f, m)
	set outputpath to quoted form of (outfolder & getFileBasename(f) & "." & outputformat)
	set thelamecmd to thelame & " -V 7 --id3v2-utf16 --tt " & (quoted form of n of m) & Â
		" --ta " & (quoted form of art of m) & " --tl " & (quoted form of alb of m) & Â
		" - " & outputpath
end compressLame

