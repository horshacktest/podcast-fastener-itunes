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
--property outfolder : choose folder with prompt "Where would you like to save the processed files?" default location path to music folder
property outfolder : "/Users/jeff/Music/Fastened/"

# Default output format. Currently only mp3 is supported
property outputformat : "mp3"

# declare global paths to executables
global sox, lame, id3cp

on run
	preflight()
	tell application "iTunes"
		local selectedTracks, f, metadata
		set selectedTracks to selection
		repeat with t in selectedTracks
			set f to location of t
			set p to my getparentfoldername(f)
			set genre of t to "Podcast"
			if album of t is "" then set album of t to p
			if artist of t is "" then set album of t to p
			set metadata to {art:(artist of t), n:(name of t), alb:(album of t), comm:(comment of t)}
			my processfile(f, metadata)
			set enabled of t to false
		end repeat
		
	end tell
end run

on getparentfoldername(f)
	tell application "Finder"
		return name of parent of f
	end tell
end getparentfoldername

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

on processfile(f, metadata)
	tell application "Finder"
		get name extension of f
	end tell
	set fileInfo to {fileRef:f, POSIXpath:quoted form of POSIX path of f}
	--set fPOSIX to fPOSIXstring as POSIX file
	set fastened to fasten(fileInfo, metadata)
	copyID3 from (POSIXpath of fileInfo) to (quoted form of POSIX path of fastened)
end processfile


-- returns a file reference of the fastened track
on fasten(fileInfo, fMetadata)
	set outputfile to (outfolder & getFileBasename(fileRef of fileInfo) & "." & outputformat)
	--error outputfile
	set thesoxcmd to sox & " " & (POSIXpath of fileInfo) & " -t raw -r 32k -e signed-integer -c 2 - compand 0.3,1 6:-70,-60,-20 -5 -90 0.2 tempo -s 1.5 dither "
	set thecompresscommand to compressLame(fMetadata)
	set fullcommand to thesoxcmd & " | " & thecompresscommand & " > " & quoted form of outputfile
	log fullcommand
	do shell script fullcommand
	return POSIX file outputfile
end fasten

to copyID3 from f to o
	do shell script id3cp & " " & f & " " & o
end copyID3



on preflight()
	log "preflight starting"
	set lame to checkcmd("lame")
	set id3cp to checkcmd("id3cp")
	set sox to checkcmd("sox")
	log "preflight done"
end preflight

on getFileBasename(f)
	tell application "Finder"
		set text item delimiters of AppleScript to "."
		-- return f
		set fn to text items 1 through -2 of (name of f as string) as string
		set text item delimiters of AppleScript to ""
	end tell
	return fn
end getFileBasename

on compressLame(m)
	--set outputpath to quoted form of (outfolder & getFileBasename(f) & "." & outputformat)
	set thelamecmd to lame & " -r -s 32 -V 7 --id3v2-utf16 --tt " & (quoted form of n of m) & Â
		" --ta " & (quoted form of art of m) & " --tl " & (quoted form of alb of m) & Â
		" - -"
end compressLame

