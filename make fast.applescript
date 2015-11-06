# TODO: impl. notifications http://macosxautomation.com/mavericks/notifications/01.html

(* 
AppleScript does not normally have access to your interactive shell profiles. Therefore, if your
commandline programs are not in the default path locations (because homebrew put them 
in /usr/local/bin) you can add that path here.

Other workarounds do exist: 
http://stackoverflow.com/questions/25385934/setting-environment-variables-via-launchd-conf-no-longer-works-in-os-x-yosemite/26586170#26586170
*)
property additionalCommandLocation : "/usr/local/bin"

# Put the location you wish for the fastened files to go to. 
# TODO: Currently there is no check protecting from filename clobbering
# TODO: Have script prompt for this if not defined
property outfolder : "~/Music/Fastened/"

# Default output format. Currently only mp3 is supported
property outputformat : "mp3"

on run
	preflight()
	#return
	#######
	tell application "iTunes"
		set selectedTracks to selection
		repeat with f in selectedTracks
			set genre of f to "Podcast"
			set fmetadata to {art:(artist of f), n:(name of f), alb:(album of f), comm:(comment of f)}
			set fl to location of f
			-- get fmetadata
			set fastreturn to my fastPipe(fl, fmetadata)
			do shell script id3cp & " " & quoted form of POSIX path of fl & " " & quoted form of POSIX path of fastreturn
			set enabled of f to false
		end repeat
		
	end tell
end run

on checkcmd(cmd)
	log "checking presence of " & cmd
	try
		return (do shell script "export PATH=$PATH:" & additionalCommandLocation & " ; which " & cmd)
	on error
		display dialog cmd & " not found"
		error
	end try
end checkcmd

------============================================----------

-- returns a file reference of the fastened track
on fastPipe(fl, fmetadata)
	set fPOSIX to quoted form of POSIX path of fl
	set outputfile to (outfolder & getFileBasename(fl) & "." & outputformat)
	set thesoxcmd to sox & " " & fPOSIX & " -t .wav - compand 0.3,1 6:-70,-60,-20 -5 -90 0.2 tempo -s 1.5 dither "
	set thecompresscommand to compressLame(fl, fmetadata)
	do shell script thesoxcmd & " | " & thecompresscommand & " &"
	log thesoxcmd & " | " & thecompresscommand & " &"
	return POSIX file outputfile
end fastPipe

on preflight()
	log "preflight starting"
	set lame to checkcmd("lame")
	set id3cp to checkcmd("id3cp")
	set sox to checkcmd("sox")
	log "preflight done"
end preflight

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
	set thelamecmd to lame & " -V 7 --id3v2-utf16 --tt " & (quoted form of n of m) & Â
		" --ta " & (quoted form of art of m) & " --tl " & (quoted form of alb of m) & Â
		" - " & outputpath
end compressLame

