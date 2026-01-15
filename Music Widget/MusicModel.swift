//
//  MusicController.swift
//  Music Widget
//
//  Created by Corvin Gröning on 04.07.22.
//

import AppleScriptObjC
import SwiftUI
import iTunesLibrary
import Combine

/// Main Model for the Music app
///
/// This class is a singleton and provides the interface to the Music app
/// and the music library. It is responsible for reading the music library,
/// getting the current track info, and controlling the player.
class MusicModel: ObservableObject {
    /// Singleton: Instance of this class (constructor must be private)
    static let shared = MusicModel()
    
    /// Instance of MusicAppBridge for communication with the Music app
    var musicAppBridge: MusicAppBridge
    
    /// Instance of the music library
    var musicSongs: [ITLibMediaItem] = []
    
    /// Status of the Music app or player
    @Published var musicState = MusicState()
    
    /// Information about a track (artist, title, etc.)
    @Published var trackInfo = Track()
    
    /// Indicates whether the song is in the library or retrieved
    /// via Apple Music
    @Published var songInLibrary = false
    
    /// Instantiate MusicAppBridge and set up observers
    private init() {
        // Load the AppleScript Objective-C scripts
        Bundle.main.loadAppleScriptObjectiveCScripts()
        
        // Create an instance of MusicAppBridge
        let musicAppBridgeClass: AnyClass = NSClassFromString("MusicAppBridge")!
        self.musicAppBridge = musicAppBridgeClass.alloc() as! MusicAppBridge
        
        // Read the music library
        self.musicSongs = self.getMusicSongs()
    }
    
    /// Saves the artwork to the disk via AppleScript and creates an Image
    /// instance from this file, which is returned.
    ///
    /// Deprecated! Use getArtworkDirectly()
    func getArtworkViaAppleScript() -> Image {
        // Get the path of the Downloads folder and create the "Music Widget"
        // folder if it doesn't exist
        let downloadsDirectory = FileManager.default.urls(
            for: .downloadsDirectory, in: .userDomainMask).first!
        let downloadsDirectoryWithFolder = downloadsDirectory
            .appendingPathComponent("Music Widget")
        
        do {
            try FileManager.default.createDirectory(
                at: downloadsDirectoryWithFolder,
                withIntermediateDirectories: true,
                attributes: nil)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        // Save artwork via AppleScript
        _ = musicAppBridge.saveArtwork()
        print("Artwork saved")
        
        // Read the JPEG file of the cover and return an Image instance
        let imgUrl = downloadsDirectoryWithFolder
            .appendingPathComponent("music_cover.jpg")
        
        do {
            let imageData = try Data(contentsOf: imgUrl)
            return Image(nsImage: NSImage(data: imageData) ?? NSImage())
        } catch {
            print("Error loading image : \(error)")
            return Image(systemName: "music.quarternote.3")
        }
    }
    
    /// Returns the artwork directly from the Music app without saving to disk
    func getArtworkDirectly() -> Image {
        // Get artwork data directly from the bridge
        guard let artworkData = musicAppBridge.artworkData() as? Data else {
            print("No artwork data available")
            return Image(systemName: "music.quarternote.3")
        }
        
        // Convert NSData to NSImage
        guard let nsImage = NSImage(data: artworkData) else {
            print("Could not create image from artwork data")
            return Image(systemName: "music.quarternote.3")
        }
        
        print("Artwork loaded directly from Music app")
        return Image(nsImage: nsImage)
    }
    
    /// Player position in seconds
    func getPlayerPosition() -> Int {
        return Int(truncating: self.musicAppBridge.playerPosition)
    }
    
    /// Class of the track ("shared track" or "URL track")
    func getTrackInLibrary() -> Bool {
        if self.musicAppBridge.trackInLibrary == 1 {
            return true
        } else {
            return false
        }
    }
    
    /// Returns the song duration (workaround for SwiftUI slider).
    func getDuration() -> Int {
        // Check if the song duration can be read, if not return 1
        
        // Check if the player is stopped
        if musicState.status == .unknown || musicState.status == .stopped {
            // If the player is stopped, return the value 1
            return 1
        } else {
            // Return the song duration
            return Int(truncating: musicAppBridge.trackDuration)
        }
    }
    
    func getFavoritedPlaylists() -> String {
        return String(describing: musicAppBridge.favoritedPlaylists)
    }
    
    func getTestTest() -> Int {
        return Int(truncating: musicAppBridge.testTest)
    }
}

extension MusicModel {
    /// Returns an array with all songs from the music library
    func getMusicSongs() -> [ITLibMediaItem] {
        musicSongs = []
        let iTunesLibrary: ITLibrary
        
        // Read the library
        do {
            iTunesLibrary = try ITLibrary(apiVersion: "1.0")
        } catch {
            print("ERROR: The music library could not be read.")
            return [ITLibMediaItem]()
        }
        
        // Save songs
        let songs = iTunesLibrary.allMediaItems
        print("\(songs.count) songs were found.")
        
        return songs
    }
}

extension MusicModel {
    /// Reads the current status of the Music app
    ///
    /// - Note: If the Music app is not running, this function calls itself
    /// after one second
    func getMusicState() async {
        if musicAppBridge._playerState == 0 {
            Task { @MainActor in
                musicState.status = MusicState.PlayerState(rawValue: 0)!
                trackInfo = Track()
            }
            /// Call itself if the Music app is not running
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await getMusicState()
        } else {
            Task { @MainActor in
                // Get the status of the Music app and track info
                musicState.status = MusicState.PlayerState(
                    rawValue: musicAppBridge._playerState as? Int ?? 0
                )!
                musicState.volume = musicAppBridge.soundVolume.doubleValue
                getTrackInfo()
                VolumeSliderData.shared.sliderValue = musicState.volume
            }
        }
    }
}

extension MusicModel {
    /// Reads the info of the current track (name, artist, etc.)
    @MainActor func getTrackInfo() {
        let bridge = musicAppBridge
        var track = Track()
        
        if bridge.isRunning, let info = bridge.trackInfo as NSDictionary? {
            track = Track(dictionary: info)
            track.cover = getArtwork(track: track)
        }
        
        trackInfo = track
        
        // Check if the song is in the library (needed to disable star ratings)
        if self.musicAppBridge.trackInLibrary == 1 {
            self.songInLibrary = true
        } else {
            self.songInLibrary = false
        }
    }
    
    /// Updates the track info in case favorite or stars were changed.
    ///
    /// TODO: Only update favorite and stars, not all data (implement update
    /// function in the Track class)
    func updatedLovedAndRating() {
        let bridge = musicAppBridge
        var track_updated = Track()
        
        if bridge.isRunning, let info = bridge.trackInfo as NSDictionary? {
            track_updated = Track(dictionary: info)
        }
        
        trackInfo.loved = track_updated.loved
        trackInfo.rating = track_updated.rating
    }
    
    /// Returns the cover image (artwork) of the current track
    ///
    /// - Note: First, it tries to load the cover from the music library.
    /// If none is found (because no cover is stored or the track is played
    /// from Apple Music and not saved in the library), it saves the cover to
    /// the disk via AppleScript and opens it with Swift. I couldn't find a way
    /// to pass the cover via MusicAppBridge.
    func getArtwork(track: Track) -> Image {
        var image = Image(systemName: "music.quarternote.3")
        
        if let match = musicSongs.first(where: {
            $0.title == track.name  &&
            $0.album.title == track.album &&
            $0.trackNumber == track.trackNumber
        })
        {
            if let coverArt = match.artwork {
                image = Image(nsImage: coverArt.image!)
                print("Cover found in library.")
            } else {
                print("Song found, but no cover.")
            }
        } else {
            // Song not in library, try via AppleScript
//            image = self.getArtworkViaAppleScript()  // Deprecated, new is:
            image = self.getArtworkDirectly() 
        }
        
        return image
    }
}

final class VolumeSliderData: ObservableObject {
    /// Singleton: Instance of this class (constructor must be private)
    static let shared = VolumeSliderData()
    
    var firstUse: Bool = true
    
    let didChange = PassthroughSubject<VolumeSliderData,Never>()
    @Published var sliderValue: Double = 0 {
        willSet {
            // Only change the volume on the second use. This ensures that the
            // volume is not set to 0 when the program starts
            // (setting MusicModel.shared.musicAppBridge.soundVolume as the
            // initial value for sliderValue leads to errors).
            if !firstUse {
                didChange.send(self)
            }
            firstUse = false
        }
    }
    
    private init() { }
}

extension MusicModel {
    /// Toggles the loved status of a track (true/false)
    @MainActor func toggleLoved() {
        // Change the loved status in the Music app
        musicAppBridge.loved = trackInfo.loved ? 0 : 1
        
        // Adjust trackInfo so that the SwiftUI display changes
        trackInfo.loved.toggle()
    }
    
    /// Sets the rating of a track
    /// - Parameter rating: Rating between 0 and 5
    @MainActor func setRating(rating: Int) {
        // If the passed rating matches the already existing one, i.e., the set
        // star was clicked in the UI, set the rating to 0
        if trackInfo.rating != rating {
            musicAppBridge.rating = NSNumber(value: rating * 20)
            trackInfo.rating = rating
        } else {
            musicAppBridge.rating = NSNumber(value: 0)
            trackInfo.rating = 0
        }
    }
}
