//
//  Track.swift
//  Music Widget
//
//  Created by Corvin Gröning on 05.07.22.
//

import SwiftUI

/// This struct represents a track in the Music app.
///
/// It contains all the information about a track, such as the artist,
/// album, title, track number, duration, rating, loved status,
/// date added, date played, play count and cover art.
struct Track: Equatable {
    var artist: String = ""
    var album: String = ""
    var name: String = ""
    var trackNumber: Int = 0
    var duration: Int = 0
    var durationFormatted: String = ""
    var rating: Int = 0
    var loved: Bool = false
    var dateAdded: String = ""
    var datePlayed: String = ""
    var playCount: String = ""
    var cover: Image = Image(systemName: "music.quarternote.3")
}

/// This extension contains the initializer for the Track struct.
///
/// It is used to create a Track object from a dictionary
/// returned by the MusicAppBridge.
extension Track {
    /// Initializes the struct with values from the MusicAppBridge.
    ///
    /// - Note: In an extension so the "memberwise initializer" can be used
    /// - Parameter dictionary: Dictionary returned by AppleScript
    init(dictionary: NSDictionary) {
        // Create date formatter for date added and last played date
        let df = DateFormatter()
        df.dateFormat = "dd MMM yy"
        
        // Retrieve values from AppleScript
        self.artist = dictionary["trackArtist"] as? String ?? ""
        self.album = dictionary["trackAlbum"] as? String ?? ""
        self.name = dictionary["trackName"] as? String ?? ""
        self.trackNumber = dictionary["trackNumber"] as? Int ?? 0
        
        if let duration = dictionary["trackDuration"] as? Double {
            self.duration = Int(duration)
            self.durationFormatted = Track.formatSeconds(Int(duration))
        } else {
            self.duration = 0
            self.durationFormatted = ""
        }
        
        self.loved = dictionary["trackLoved"] as? Bool ?? false
        
        // If the song is not in the library, the following values
        // might not be available
        if dictionary["trackDateAdded"] is NSNull {
            self.dateAdded = "n.a."
        } else {
            self.dateAdded = df.string(
                from: dictionary.value(forKey: "trackDateAdded") as! Date
            )
        }
        
        if dictionary["trackDatePlayed"] is NSNull {
            self.datePlayed = "n.a."
        } else {
            self.datePlayed = df.string(
                from: dictionary.value(forKey: "trackDatePlayed") as! Date
            )
        }
        
        if dictionary["trackPlayCount"] is NSNull {
            self.playCount = "n.a."
        } else {
            self.playCount = String(dictionary.value(
                forKey: "trackPlayCount") as! Int
            )
        }
        
        // The track's rating is stored in the library as a percentage (0-100).
        // The UI, however, offers 0-5 stars.
        // Therefore, the value is divided by 20 (e.g. 100/5=20).
        if let rating = dictionary["trackRating"] as? Int {
            self.rating = rating / 20
        } else {
            self.rating = 0
        }
    }
}

extension Track {
    /// Converts a value given in seconds into a time-formatted string.
    /// Example: 90 -> "1m 30s"
    ///
    /// - Parameter duration: NSNumber; track length in seconds
    /// - Returns: Time-formatted string
    static func formatSeconds(_ duration: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: TimeInterval(exactly: duration)!)!
    }
}
