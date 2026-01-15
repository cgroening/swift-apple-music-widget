//
//  Support.swift
//  Swift-AppleScriptObjC
//

import Cocoa

/// This protocol defines the interface for the Music app and the methods
/// that can be called from Swift.
///
/// - Important:
/// ASOC does not bridge C data types, only Cocoa classes and objects,
/// i.e., the Swift data types Bool/Int/Double must be explicitly
/// converted to/from NSNumber when communicating with AppleScript.
@objc(NSObject) protocol MusicAppBridge {
    /// Indicates whether the Music app is running (Bool)
    var _isRunning: NSNumber { get }
    
    /// Player status (stopped, playing, paused, fast forwarding, rewinding)
    var _playerState: NSNumber { get }
    
    /// Player position (in seconds)
    var playerPosition: NSNumber { get set }
    
    /// Array: Title, artist, etc., of the current track
    var trackInfo: [NSString:AnyObject]? { get }
    
    /// Indicates whether the track is in the library (1)
    /// or from Apple Music (0)
    var trackInLibrary: NSNumber { get }
    
    /// Track duration for the progress bar (workaround)
    var trackDuration: NSNumber { get }
    
    /// Player volume
    var soundVolume: NSNumber { get set }
    
    /// Loved status
    var loved: NSNumber { get set }
    
    /// Track Rating (0-100)
    var rating: NSNumber { get set }
    
    /// Date the track was added to the library
    var dateAdded: NSDate { get }
    
    /// Date the track was last played
    var datePlayed: NSDate { get }
    
    /// Play count of the current track
    var playCount: NSNumber { get }
    
    /// Starts or pauses the player's playback
    func playPause()
    
    /// Jumps to the next track
    func gotoPreviousTrack()
    
    /// Jumps to the previous track
    func gotoNextTrack()
    
    /// Indicates whether shuffle is enabled
    var shuffleEnabled: NSNumber { get }
    
    // Toggles shuffle mode
    func toggleShuffle()
    
    /// Returns the repeat setting for tracks (off, all, or one)
    ///
    /// - Returns:
    ///   - `<NSAppleEventDescriptor: 'kRp0'>` (off)
    ///   - `<NSAppleEventDescriptor: 'kAll'>` (all)
    ///   - `<NSAppleEventDescriptor: 'kRp1'>` (one)
    var songRepeat: NSAppleEventDescriptor { get }
    
    /// Cycles through repeat settings: all -> one -> off
    func toggleSongRepeat()
    
    /// Saves the artwork of the current track in the Application Support folder
    /// Deprecated: Use artworkData()
    func saveArtwork() -> NSString

    /// Returns the artwork data directly as NSData
    func artworkData() -> NSData?
    
    /// Returns a list of playlists marked as favorites
    var favoritedPlaylists: NSString { get }
    
    /// Example property for testing purposes
    ///
    /// - TODO: Remove this property in the final version
    var testTest: NSNumber { get }
}

/// Native Swift version of the ASOC APIs defined above
extension MusicAppBridge {
    /// Indicates whether the Music app is running
    var isRunning: Bool {
        return self._isRunning.boolValue
    }
    
    /// Player state (unknown stopped, playing, paused, fast forwarding
    /// or rewinding)
    var playerState: PlayerState {
        return PlayerState(rawValue: self._playerState as! Int)!
    }
}

/// Represents the state of the Music app
@objc enum PlayerState: Int {
    /// The Music app is not running
    case unknown
    
    /// The player is stopped
    case stopped
    
    /// The player is playing
    case playing
    
    /// The player is paused
    case paused
    
    /// The player is fast-forwarding
    case fastForwarding
    
    /// The player is rewinding
    case rewinding
}
