//
//  AppDelegate.swift
//  Music Widget
//
//  Created by Corvin Gröning on 05.07.22.
//

import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    /// Shared instance of the MusicModel
    let musicModel: MusicModel = .shared
    
    /// AppStorage variable to store the "Always On Top" state
    @AppStorage("alwaysOnTopDisabled") var alwaysOnTopDisabled = false
    
    /// Event monitor for key presses
    var keyEventMonitor: Any?
    
    /// Stores volume before muting
    var volumeBeforeMute: Double = 50
    
    /// Creates an observer for "com.apple.Music.playerInfo" and sets
    /// `window.level = .floating` for all windows if the
    /// "Always On Top" setting is disabled.
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Observer
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(self, selector: #selector(AppDelegate.updateState),
                        name: NSNotification.Name(
                            rawValue: "com.apple.Music.playerInfo"
                        ),
                        object: "com.apple.Music.player")
        
        // Set the window level to floating if "Always On Top" is disabled
        for window in NSApplication.shared.windows {
            window.level = alwaysOnTopDisabled ? .normal : .floating
        }
        
        // Initialize key event monitor
        setupKeyEventMonitor()
    }
    
    /// Setups the key event monitor for the F keys
    func setupKeyEventMonitor() {
        keyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            event in
            
            // Debugging:
//            print("Key pressed: \(event.keyCode)")
//            print("Modifiers: \(event.modifierFlags)")  // Debug
            
            // Check for modifiers
            let relevantModifiers: NSEvent.ModifierFlags = [
                .command, .option, .control, .shift
            ]
            let hasRelevantModifiers = !event.modifierFlags
                .intersection(relevantModifiers).isEmpty
            
            // Only run if no modifier is pressed
            if !hasRelevantModifiers {
                // Check for F1 to F12
                switch event.keyCode {
                    case 122: // F1 - Set rating to 1
                        Task { @MainActor in
                            if self.musicModel.trackInfo.rating != 1 {
                                self.musicModel.setRating(rating: 1)
                            } else {
                                self.musicModel.setRating(rating: 0)
                            }
                        }
                        return nil
                    case 120: // F2 - Set rating to 2
                        Task { @MainActor in
                            if self.musicModel.trackInfo.rating != 2 {
                                self.musicModel.setRating(rating: 2)
                            } else {
                                self.musicModel.setRating(rating: 0)
                            }
                        }
                        return nil
                    case 99:  // F3 - Set rating to 3
                        Task { @MainActor in
                            if self.musicModel.trackInfo.rating != 3 {
                                self.musicModel.setRating(rating: 3)
                            } else {
                                self.musicModel.setRating(rating: 0)
                            }
                        }
                        return nil
                    case 118: // F4 - Set rating to 4
                        Task { @MainActor in
                            if self.musicModel.trackInfo.rating != 4 {
                                self.musicModel.setRating(rating: 4)
                            } else {
                                self.musicModel.setRating(rating: 0)
                            }
                        }
                        return nil
                    case 96:  // F5 - Set rating to 5
                        Task { @MainActor in
                            if self.musicModel.trackInfo.rating != 5 {
                                self.musicModel.setRating(rating: 5)
                            } else {
                                self.musicModel.setRating(rating: 0)
                            }
                        }
                        return nil
                    case 97:  // F6 - Toggle loved/favorite
                        Task { @MainActor in
                            self.musicModel.toggleLoved()
                        }
                        return nil
                    case 98:  // F7 - Previous track
                        self.musicModel.musicAppBridge.gotoPreviousTrack()
                        return nil
                    case 100: // F8 - Play/Pause
                        self.musicModel.musicAppBridge.playPause()
                        return nil
                    case 101: // F9 - Next track
                        self.musicModel.musicAppBridge.gotoNextTrack()
                        return nil
                    case 109: // F10 - Toggle Mute
                        Task { @MainActor in
                            let currentVolume = VolumeSliderData.shared.sliderValue
                            
                            if currentVolume > 0 {
                                // Currently not muted -> mute and save current volume
                                self.volumeBeforeMute = currentVolume
                                VolumeSliderData.shared.sliderValue = 0
                                self.musicModel.musicAppBridge.soundVolume = NSNumber(value: 0)
                            } else {
                                // Currently muted -> restore previous volume
                                VolumeSliderData.shared.sliderValue = self.volumeBeforeMute
                                self.musicModel.musicAppBridge.soundVolume = NSNumber(
                                    value: self.volumeBeforeMute
                                )
                            }
                        }
                        return nil
                    case 103: // F11 - Volume down
                        Task { @MainActor in
                            let currentVolume = VolumeSliderData.shared.sliderValue
                            let newVolume = max(0, currentVolume - 5)
                            VolumeSliderData.shared.sliderValue = newVolume
                            self.musicModel.musicAppBridge.soundVolume = NSNumber(value: newVolume)
                        }
                        return nil
                    case 111: // F12 - Volume up
                        Task { @MainActor in
                            let currentVolume = VolumeSliderData.shared.sliderValue
                            let newVolume = min(100, currentVolume + 5)
                            VolumeSliderData.shared.sliderValue = newVolume
                            self.musicModel.musicAppBridge.soundVolume = NSNumber(value: newVolume)
                        }
                        return nil
                    default:
                        break
                }
            }
            return event
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Nothing happens here, yet.
    }
    
    /// Updates the Music Model after the Music app triggers the signal
    /// "com.apple.Music.playerInfo"
    @objc func updateState(_ aNotification: Notification) {
        // Is a track playing?
        if let message = aNotification.userInfo as NSDictionary?,
           message["Name"] as? String == nil {
            // No music is playing or the Music app is being closed,
            // wait a second to avoid AppleScript errors
            sleep(1)
        }
        Task {
            await musicModel.getMusicState()
        }
    }
}
