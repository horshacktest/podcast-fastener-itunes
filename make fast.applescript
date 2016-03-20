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
# TODO: Currently there is no check protecting from filename clobbering in the destination path
property outputfolder : choose folder with prompt "Where would you like to save the processed files?" default location path to music folder

# Default output format. Currently only mp3 is supported
property outputformat : ".mp3"

# declare global paths to executables
global sox, lame

on run
	preflight()
	tell application "iTunes"
		local sourceFile, itunesTrack, selectedTracks, trackData
		set selectedTracks to selection
		repeat with itunesTrack in selectedTracks
			my fixupiTunesMetadata(itunesTrack)
			--create data object
			set sourceFile to location of itunesTrack
			set trackData to {sourcePath:"", destinationPath:"", metadata:{}, artworkpath:""}
			set sourcePath of trackData to POSIX path of sourceFile
			set destinationPath of trackData to outputfolder & my getfilebasename(sourceFile) & outputformat
			set metadata of trackData to {art:(artist of itunesTrack), title:(name of itunesTrack), alb:(album of itunesTrack), comm:(comment of itunesTrack), tracknum:(track number of itunesTrack), yr:(year of itunesTrack)}
			-- handle artwork logic
			set artworkpath of trackData to my getPathToArtworkFile(itunesTrack)
			get trackData
			--do the work
			my fasten(trackData)
			set enabled of itunesTrack to false
			--cleanup artwork file
		end repeat
		
	end tell
end run

-- ARTWORK STUFF -------------------------------------
on getPathToArtworkFile(itunesTrack)
	local artworkpath
	set artworkpath to dumpArtworkToFile(itunesTrack)
	if artworkpath is not "" then
		return artworkpath
	end if
	set artworkpath to resolveDefaultArtwork(itunesTrack)
	if artworkpath is not "" then
		return artworkpath
	end if
	-- no file found
	return ""
end getPathToArtworkFile

on checkForTrackArtwork(itunesTrack)
	tell application "iTunes"
		if (count of artworks in itunesTrack) is greater than 0 then
			return first artwork of itunesTrack
		else
			return false
		end if
	end tell
end checkForTrackArtwork

on getArtworkDataFormat(art)
	tell application "iTunes"
		if format of art is Çclass PNG È then
			return {mime:"image/png", ext:".png"}
		else if format of art is JPEG picture then
			return {mime:"image/jpeg", ext:".jpg"}
		end if
	end tell
end getArtworkDataFormat

on dumpArtworkToFile(itunesTrack)
	set art to checkForTrackArtwork(itunesTrack)
	if art is not false then
		return dumpArtworkToFileUsingiTunes(itunesTrack, art)
	else
		return ""
	end if
end dumpArtworkToFile

--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
on resolveDefaultArtwork(itunesTrack)
	local loc, currentFolder, defaultArt
	tell application "iTunes"
		set loc to location of itunesTrack
	end tell
	tell application "System Events"
		set currentFolder to path of container of loc
		try
			set defaultArt to POSIX path of file (currentFolder & "albumart.jpg")
		on error
			try
				set defaultArt to POSIX path of file (currentFolder & "albumart.png")
			on error
				set defaultArt to ""
			end try
		end try
	end tell
	return defaultArt
end resolveDefaultArtwork

on dumpArtworkToFileUsingiTunes(itunesTrack, art)
	local loc, ppath, pic, destinationPath, destination, filehandle
	tell application "iTunes"
		set loc to location of itunesTrack
		set pic to data of art
	end tell
	tell application "Finder"
		set destinationPath to (loc as text) & ext of my getArtworkDataFormat(art)
		set destination to a reference to file destinationPath
	end tell
	set filehandle to open for access destination with write permission
	write pic to filehandle
	close access filehandle
	return POSIX path of (destinationPath)
end dumpArtworkToFileUsingiTunes

on dumpArtworkToFileUsingMediainfo(source, destination)
	do shell script "/usr/local/bin/mediainfo --Output=General\\;%Cover_Data% " & source & " | base64 -D > " & destination
	return destination
end dumpArtworkToFileUsingMediainfo



------============================================----------

on fixupiTunesMetadata(itunesTrack)
	local parentFolder
	tell application "iTunes"
		set parentFolder to my getparentfoldername(location of itunesTrack)
		set genre of itunesTrack to "Podcast"
		if album of itunesTrack is "" then set album of itunesTrack to parentFolder
		if artist of itunesTrack is "" then set artist of itunesTrack to parentFolder
	end tell
end fixupiTunesMetadata

on fasten(trackData)
	local inputfile, outputfile, thesoxcommand, thecompresscommand, fullcommand
	set inputfile to quoted form of (sourcePath of trackData)
	set outputfile to quoted form of (destinationPath of trackData)
	set thesoxcommand to buildSoxCommand(inputfile, 1.7)
	--log thesoxcommand
	set thecompresscommand to buildLameCommand(trackData)
	--log thecompresscommand
	set fullcommand to thesoxcommand & " | " & thecompresscommand & outputfile
	log fullcommand
	do shell script fullcommand
end fasten

on buildSoxCommand(inputfile, tempofactor)
	local formatoptions, dynamicrangeoptions, tempooptions, thesoxcommand
	set formatoptions to " " & inputfile & " -t raw -r 32k -e signed-integer -c 2 - "
	set dynamicrangeoptions to " compand 0.3,1 6:-70,-60,-20 -5 -90 0.2 "
	set tempooptions to " tempo -s " & tempofactor & " dither "
	set thesoxcommand to sox & formatoptions & dynamicrangeoptions & tempooptions
end buildSoxCommand

on buildLameCommand(trackData)
	local formatoptions, id3options
	--NOTE: lame writes id3v2.3 tags
	set formatoptions to " -r -s 32 -V 7 "
	set id3options to " --id3v2-only " & buildLameId3Options(trackData)
	set thelamecmd to lame & formatoptions & id3options & " - "
end buildLameCommand

on buildLameId3Options(trackData)
	local m, tt, ta, tl, tg, ty, tn, tc, ti
	set m to metadata of trackData
	set tt to " --tt " & (quoted form of title of m)
	set ta to " --ta " & (quoted form of art of m)
	set tl to " --tl " & (quoted form of alb of m)
	set tg to " --tg Podcast"
	if yr of m is not "" then
		set ty to " --ty " & (yr of m)
	else
		set ty to ""
	end if
	if tracknum of m is not 0 then
		set tn to " --tn " & (tracknum of m)
	else
		set tn to ""
	end if
	if comm of m is not "" then
		set tc to " --tc " & (quoted form of comm of m)
	else
		set tc to ""
	end if
	if artworkpath of trackData is not "" then
		set ti to " --ti " & (quoted form of artworkpath of trackData)
	else
		set ti to ""
	end if
	
	return tt & ta & tl & tg & ty & tn & tc & ti
end buildLameId3Options

on preflight()
	log "preflight starting"
	set lame to checkcmd("lame")
	set sox to checkcmd("sox")
	log "preflight done"
end preflight

on getfilebasename(filealias)
	tell application "Finder"
		get name extension of filealias
		set text item delimiters of AppleScript to "."
		set basename to text items 1 through -2 of (name of filealias as string) as string
		set text item delimiters of AppleScript to ""
	end tell
	return basename
end getfilebasename

on getparentfoldername(filealias)
	tell application "Finder"
		return name of parent of filealias
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
