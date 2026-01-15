script MusicAppBridge
    property parent : class "NSObject"
    
    # AppleScript will automatically start the program to communicate with
    # (here: com.apple.Music) before sending Apple events.
    # If this is not desired it can be checked with the running property.
    to _isRunning() -- () -> NSNumber (Bool)
    return running of application id "com.apple.Music"
end isRunning

# Status of the player (stopped, playing, paused, fast forwarding, rewinding)
to _playerState() -- () -> NSNumber (PlayerState)
tell application id "com.apple.Music"
    if running then
        set currentState to player state
        set i to 1
        
        repeat with stateEnumRef in {stopped, playing, paused, ¬
            fast forwarding, rewinding}
            if currentState is equal to contents of stateEnumRef then
                return i  # Return the status
            end if
            
            set i to i + 1
        end repeat
    end if
    return 0  # Status is unknown
end tell
end playerState

# Gets the player's position (in seconds)
to playerPosition() -- () -> NSNumber (Double, >=0)
tell application id "com.apple.Music"
    return player position
end tell
end playerPosition

# Sets the player's position (in seconds)
to setPlayerPosition:newPosition -- NSNumber (Double, >=0) -> ()
tell application id "com.apple.Music"
    set player position to newPosition as integer
end tell
end setPlayerPosition:

# Starts or pauses the player's playback
to playPause()
tell application id "com.apple.Music" to playpause
end playPause

# Jumps to the next track
to gotoNextTrack()
tell application id "com.apple.Music" to next track
end gotoNextTrack

# Jumps to the previous track
to gotoPreviousTrack()
tell application id "com.apple.Music" to previous track
end gotoPreviousTrack

# Indicates whether shuffle is enabled
to shuffleEnabled()
tell application id "com.apple.Music"
    return shuffle enabled
end tell
end isShuffleEnabled

# Toggles shuffle on/off
to toggleShuffle()
tell application id "com.apple.Music"
    if shuffle enabled then
        set shuffle enabled to false
        else
        set shuffle enabled to true
    end if
end tell
end toggleShuffle

# Returns the repeat setting for tracks (off, all, or one)
to songRepeat()
tell application id "com.apple.Music"
    return song repeat
end tell
end songRepeat

# Returns a list of playlists marked as favorite
to favoritedPlaylists()
tell application "System Events"
    tell application "Music"
        set playlistDetails to {}
        repeat with aPlaylist in playlists
            try
                # Check if the playlist is favorited
                if (favorited of aPlaylist) is true then
                    set end of playlistDetails to name of aPlaylist
                end if
                on error errMsg
                # If there is an error, return it as text
                return "Error: " & errMsg
            end try
        end repeat
        
        # If no favorites are found, explicitly return that
        if (count of playlistDetails) = 0 then
            return "No favorites found"
        end if
        
        return playlistDetails
    end tell
end tell
end favoritedPlaylists

# Test function returning a number
# TODO: Remove this function in the final version
to testTest() -- () -> NSNumber (Double, >= 0)
return 1234
end testTest

# Cycles through the repeat settings: all -> one -> off
to toggleSongRepeat()
tell application id "com.apple.Music"
    if song repeat is off then
        set song repeat to all
        else if song repeat is all then
        set song repeat to one
        else
        set song repeat to off
    end if
end tell
end toggleSongRepeat

# Gets the player's volume
to soundVolume() -- () -> NSNumber (Int, 0...100)
tell application id "com.apple.Music"
    return sound volume
end tell
end soundVolume

# Sets the player's volume
to setSoundVolume:newVolume -- (NSNumber) -> ()
tell application id "com.apple.Music"
    set sound volume to newVolume as integer
end tell
end setSoundVolume:

# Array with the name, artist, and album of the current track
to trackInfo()  -- () -> [
#        "trackArtist":NSString,
#        "trackAlbum":NSString,
#        "trackName":NSString,
#        "trackNumber":NSNumber,
#        "trackDuration":NSNumber (Double, >= 0),
#        "trackRating":NSNumber (Int, 0...100),
#        "trackLoved":NSNumber,
#       ]?
tell application id "com.apple.Music"
    try
        return {trackArtist:artist, ¬
        trackAlbum:album, ¬
        trackName:name, ¬
        trackNumber:track number, ¬
        trackDuration:duration, ¬
        trackRating:rating, ¬
        trackLoved:favorited, ¬
        trackDateAdded:date added, ¬
        trackDatePlayed:played date, ¬
        trackPlayCount:played count ¬
        } of current track
        on error number -1728  -- "current track" is not available
        return missing value   -- nil
    end try
end tell
end trackInfo

# Indicates whether the track is in the library (1) or from Apple Music (0)
to trackInLibrary() -- () -> NSNumber (Bool)
tell application id "com.apple.Music"
    set cls to class of current track
    if cls is URL track then
        return 0
        else
        return 1
    end if
end tell
end trackDuration

# Track duration for slider (workaround)
to trackDuration() -- () -> NSNumber (Double, >= 0)
tell application id "com.apple.Music"
    return duration of current track
end tell
end trackDuration

# Sets the track's rating in % (0 stars -> 0, 1 star -> 1, etc.)
to setRating:newRating -- (NSNumber) -> ()
tell application id "com.apple.Music"
    set rating of current track to newRating as integer
end tell
end setRating:

# Sets the track's loved status (true, false)
to setLoved:newLoved -- (NSNumber) -> ()
tell application id "com.apple.Music"
    set favorited of current track to newLoved as boolean
end tell
end setLoved:

# Saves the artwork of the current track and returns the path
# Deprecated! Use artworkData()
to saveArtwork() -- () -> NSString
# Get raw image data
    tell application id "com.apple.Music" to tell artwork 1 of current track
        set srcBytes to raw data

        # Determine file extension (.png or .jpg)
        if format is «class PNG » then
            set ext to ".png"
            else
            set ext to ".jpg"
        end if
    end tell

    # Set file name ([Downloads folder]/Music Widget/music_cover.ext)
    set fileName to POSIX path of ((((path to downloads folder ¬
    from user domain) as text) & "Music Widget:" as text) ¬
    & "music_cover" & ext)

    # Begin file access
    set outFile to open for access fileName with write permission

    # Truncate file
    set eof outFile to 0

    # Write file
    write srcBytes to outFile

    # End file access
    close access outFile

    return fileName
end saveArtwork

# Returns the artwork as raw NSData without saving to disk
to artworkData() -- () -> NSData
tell application id "com.apple.Music"
    try
        # Get the raw image data from the current track's artwork
        tell artwork 1 of current track
            return raw data
        end tell
        on error
        # If no artwork is available, return missing value
        return missing value
    end try
end tell
end artworkData

end script
