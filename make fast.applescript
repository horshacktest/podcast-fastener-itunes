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
#property outputfolder : path to music folder

# Default output format. Currently only mp3 is supported
property outputformat : ".mp3"

# declare global paths to executables
global sox, lame

-- ARTWORK STUFF -------------------------------------
-- this is entry function for artwork resolution
on getPathToArtworkFile(itunesTrack)
	-- declare local vars for complete POSIX path to artwork image, parent folder file alias, track file alias
	local artworkpath, itunesTrackFileAlias
	tell application "iTunes"
		set itunesTrackFileAlias to location of itunesTrack
	end tell
	-- First try setting artwork to the override if it exists
	set artworkpath to getOverrideArtworkPath(itunesTrackFileAlias)
	
	-- Next try to extract artwork from the actual track.
	-- Try this because some pods have unique ablumart for each episode.
	if artworkpath is "" then
		set artworkpath to dumpArtworkToFile(itunesTrack)
	end if
	
	-- Last try to get the path of the default albumart
	-- TODO change the parameter to pass the parent, that's all that's needed
	if artworkpath is "" then
		set artworkpath to checkDefaultArtwork(itunesTrack)
	end if
	return artworkpath
end getPathToArtworkFile


-- artwork files in the folder named after the current file + '.jpg' will take precedence over
-- all other artwork. (over albumart.png, albumart.jpg) if default.jpg exists it is a folderwide override
on getOverrideArtworkPath(itunesTrackFileAlias)
	local overrideArt
	try
		set overrideArt to POSIX path of alias ((itunesTrackFileAlias as string) & ".jpg")
	on error
		try
			set overrideArt to POSIX path of alias ((getparentfolderalias(itunesTrackFileAlias) as string) & "default.jpg")
		on error
			set overrideArt to ""
		end try
	end try
	return overrideArt
end getOverrideArtworkPath


on checkDefaultArtwork(itunesTrack)
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
end checkDefaultArtwork

--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

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
		-- TODO do type check to make sure this is artwork. one time someone had a string in the artwork field. Looks like they though it was "artist" not "artwork" ??
		return dumpArtworkToFileUsingiTunes(itunesTrack, art)
	else
		return ""
	end if
end dumpArtworkToFile


on dumpArtworkToFileUsingiTunes(itunesTrack, art)
	local loc, path, pic, destinationPath, destination, filehandle
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

------============================================----------

on fixupiTunesMetadata(itunesTrack)
	local parentFolderName
	tell application "iTunes"
		set parentFolderName to my getparentfoldername(location of itunesTrack)
		set genre of itunesTrack to "Podcast"
		if album of itunesTrack is "" then set album of itunesTrack to parentFolderName
		if artist of itunesTrack is "" then set artist of itunesTrack to parentFolderName
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
	set id3options to "--id3v2-latin1 --id3v2-only " & buildLameId3Options(trackData)
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

on getparentfolderalias(filealias)
	tell application "Finder"
		return parent of filealias
	end tell
end getparentfolderalias

on getparentfoldername(filealias)
	tell application "Finder"
		return name of my getparentfolderalias(filealias)
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
			set destinationPath of trackData to POSIX path of outputfolder & my getfilebasename(sourceFile) & outputformat
			set metadata of trackData to {art:(artist of itunesTrack), title:(name of itunesTrack), alb:(album of itunesTrack), comm:(comment of itunesTrack), tracknum:(track number of itunesTrack), yr:(year of itunesTrack)}
			-- handle artwork logic
			set artworkpath of trackData to my getPathToArtworkFile(itunesTrack)
			--get trackData
			--do the work
			my fasten(trackData)
			
			set rating of itunesTrack to 99
			--set played count of itunesTrack to 1
			--set enabled of itunesTrack to false
			-- TODO cleanup artwork file
		end repeat
		
	end tell
end run
