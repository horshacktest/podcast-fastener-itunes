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
--property outputfolder : choose folder with prompt "Where would you like to save the processed files?" default location path to music folder
property outputfolder : "/Users/jeff/Music/Fastened/"

# Default output format. Currently only mp3 is supported
property outputformat : "mp3"

# declare global paths to executables
global sox, lame, id3cp, id3tag, eyeD3

on run
	preflight()
	tell application "iTunes"
		local selectedTracks, t, f, p, metadata
		set selectedTracks to selection
		repeat with t in selectedTracks
			set f to location of t
			set p to my getparentfoldername(f)
			set genre of t to "Podcast"
			if album of t is "" then set album of t to p
			if artist of t is "" then set artist of t to p
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
	set fileInfo to {fileRef:f, POSIXpath:quoted form of POSIX path of f}
	--fixID3v24(POSIXpath of fileInfo)
	--fixBlankSongName(quoted form of (n of metadata), POSIXpath of fileInfo)
	set fastened to fasten(fileInfo, metadata)
	copyID3 from (POSIXpath of fileInfo) to (quoted form of POSIX path of fastened)
end processfile


-- returns a file reference of the fastened track
on fasten(fileInfo, fMetadata)
	set outputfile to (outputfolder & getfilebasename(fileRef of fileInfo) & "." & outputformat)
	set thesoxcmd to sox & " " & (POSIXpath of fileInfo) & " -t raw -r 32k -e signed-integer -c 2 - compand 0.3,1 6:-70,-60,-20 -5 -90 0.2 tempo -s 1.5 dither "
	set thecompresscommand to compresslame(fMetadata)
	set fullcommand to thesoxcmd & " | " & thecompresscommand & quoted form of outputfile
	log fullcommand
	do shell script fullcommand
	return POSIX file outputfile
end fasten

to copyID3 from f to o
	-- NOTE: id3cp does not seem to copy v2.4 tags
	do shell script id3cp & " -2 " & f & " " & o
end copyID3

on fixID3v24(f)
	--NOTE: crashes when trying to convert "Functional Geekery Podcast"
	do shell script eyeD3 & " -Q --to-v2.3 " & f
end fixID3v24

on fixBlankSongName(trackname, tracklocation)
	--NOTE: if iTunes is not managing files in the iTunes library location, files 
	--do not get renamed to their id3 song name. So my idea that this would be a noop 
	--for files having names is inaccurate. 
	do shell script "/usr/local/bin/id3tag -2 -s" & trackname & " " & tracklocation
end fixBlankSongName


on preflight()
	log "preflight starting"
	set lame to checkcmd("lame")
	set id3cp to checkcmd("id3cp")
	set id3tag to checkcmd("id3tag")
	set sox to checkcmd("sox")
	set eyeD3 to checkcmd("eyeD3")
	log "preflight done"
end preflight

on getfilebasename(f)
	tell application "Finder"
		get name extension of f
		set text item delimiters of AppleScript to "."
		set fn to text items 1 through -2 of (name of f as string) as string
		set text item delimiters of AppleScript to ""
	end tell
	return fn
end getfilebasename

on compresslame(m)
	--NOTE: lame writes id3v2.3 tags
	set thelamecmd to lame & " -r -s 32 -V 7 --id3v2-only --tt " & (quoted form of n of m) & Â
		" --ta " & (quoted form of art of m) & " --tl " & (quoted form of alb of m) & Â
		" - "
end compresslame

