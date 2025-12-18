//
//  Music_WidgetApp.swift
//  Music Widget
//
//  Created by Corvin Gröning on 04.07.22.
//

import SwiftUI

@main
struct Music_WidgetApp: App {
    /// Instance of MusicModel (Singleton)
    @StateObject var musicModel: MusicModel = .shared
    
    /// Instance of the class for the volume value
    @StateObject var volumeSliderData: VolumeSliderData = .shared
    
    /// Instance of the Timer class
    @StateObject var timers: Timers = .shared
    
    /// Indicates whether the timer should be paused
    @State var timerPaused: Bool = false
    
    /// App delegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    /// Indicates whether the app should always be displayed "Always On Top"
    @AppStorage("alwaysOnTopDisabled") var alwaysOnTopDisabled: Bool = false
    
    /// Indicates whether the warning for when the track is about to end
    /// but has not yet been rated should be disabled
    @AppStorage("songNotRatedWarningDisabled")
    var songNotRatedWarningDisabled: Bool = false
    
    /// App that was active before this one was automatically activated
    @State var activeAppBeforeHover: Optional<NSRunningApplication> = nil
    
    /// Window width
    let windowWidth: CGFloat = 395
    
    /// Window width
    let windowHeight: CGFloat = 100
    
    /// Code to be executed when the app starts
    init() {
        // Nothing happens here, yet
    }
    
    /// Display the scene
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    DispatchQueue.main.async {
                        NSApplication.shared.windows.forEach { window in
                            // Hide minimize and maximize buttons
                            window.standardWindowButton(.miniaturizeButton)?
                                .isEnabled = false
                            window.standardWindowButton(.miniaturizeButton)?
                                .isHidden = true
                            
                            window.standardWindowButton(.zoomButton)?
                                .isEnabled = false
                            window.standardWindowButton(.zoomButton)?
                                .isHidden = true
                        }
                    }
                }
                .onHover(perform: { hovering in
                    /// If the window is not active, the buttons cannot be
                    /// clicked. It requires two clicks:
                    /// 1. Activate the window
                    /// 2. Press the button.
                    /// To ensure only one click is necessary, the following
                    /// code ensures that the window is automatically activated
                    /// when the mouse pointer moves into it.
    
                    if hovering {
                        // Mouse pointer moved into the window:
                        // Save the instance of the app that is currently active
                        self.activeAppBeforeHover =
                            NSWorkspace.shared.frontmostApplication
                        
                        // Activate this app
                        NSApp.activate(ignoringOtherApps: true)
                    } else {
                        // Mouse pointer moved out of the window:
                        // Activate the app that was previously active
                        if self.activeAppBeforeHover != nil {
                            self.activeAppBeforeHover?.activate()
                        }
                    }
                })
            
                // Frame width and height
                .frame(
                    // Width
                    minWidth: windowWidth,
                   idealWidth: windowWidth,
                   maxWidth: .infinity,
                    // Height
                   minHeight: windowHeight,
                   idealHeight: windowHeight,
                   maxHeight: windowHeight)
                .fixedSize()
            
                // Environment Objects
                .environmentObject(musicModel)
                .environmentObject(volumeSliderData)
            
                // Toolbar
                .toolbar {
                    // Toggle for enabling/disabling "Always On Top"
                    ToolbarItem {
                        Toggle(isOn: $alwaysOnTopDisabled) {
                            Image(systemName: alwaysOnTopDisabled ?
                                              "square.stack.3d.up.slash.fill" :
                                              "square.stack.3d.up.fill"
                            )
                        }
                        .onChange(of: alwaysOnTopDisabled) {
                            oldValue, newValue in
                            // Is "Always On Top" disabled?
                            for window in NSApplication.shared.windows {
                                window.level = alwaysOnTopDisabled ?
                                    .normal : .floating
                            }
                        }
                        .help("Disable the \"always on top\"-functionality?")
                        .padding(.trailing, -5)
                    }
                    
                    // Toggle for enabling/disabling rating warning
                    ToolbarItem {
                        Toggle(isOn: $songNotRatedWarningDisabled) {
                            Image(systemName:
                                    songNotRatedWarningDisabled ?
                                  "bell.slash.fill" :
                                    "bell.fill")
                        }
                        .onChange(of: songNotRatedWarningDisabled) {
                            oldValue, newValue in
                            // Nothing happens here yet.
                        }
                        .help("Disable the warning (blinking rating stars and "
                              + "beep sound) that will be triggered when a track "
                              + "is about to end but hasn't been rated, yet.")
                    }
                    
                    // Buttons for Previous, Play/Pause, Next
                    ToolbarItem {
                        Button(action: {
                            musicModel.musicAppBridge.gotoPreviousTrack()
                        }, label: {
                            Image(systemName: "backward.fill")
                        })
                        .frame(width: 30)
                        .padding(.trailing, -10)
                    }
                    ToolbarItem {
                        Button(action: {
                            musicModel.musicAppBridge.playPause()
                        }, label: {
                            Image(systemName: musicModel.musicState.status ==
                                .playing ? "pause.fill" : "play.fill")
                        })
                        .frame(width: 30)
                        .padding(.trailing, -10)
                    }
                    ToolbarItem {
                        Button(action: {
                            musicModel.musicAppBridge.gotoNextTrack()
                        }, label: {
                            Image(systemName: "forward.fill")
                        })
                        .frame(width: 30)
                        .padding(.trailing, 0)
                    }
                    
                    // Buttons and slider for volume
                    ToolbarItem {
                        Button(action: {
                            // Volume = 0
                            volumeSliderData.sliderValue = 0
                            musicModel.musicAppBridge.soundVolume =
                            NSNumber(value: 0)
                        }, label: {
                            Image(systemName: "speaker.fill")
                        })
                    }
                    ToolbarItem {
                        // This slider adjusts the volume while being dragged
                        // and when released. The additional adjustment on
                        // release is necessary in case the slider is moved
                        // very quickly to the left or right. In such cases,
                        // the correct volume might not be set during dragging.
                        Slider(value: $volumeSliderData.sliderValue, in: 0...100,
                               onEditingChanged: { sliderBeingDragged in
                            // Pause the timer while the slider is being dragged
                            timerPaused = sliderBeingDragged ? true : false
                            
                            // Volume = Slider value
                            musicModel.musicAppBridge.soundVolume =
                            NSNumber(value: volumeSliderData.sliderValue)
                        })
                        .frame(width: 65)
                        .padding(.leading, -3)
                        .padding(.trailing, -3)
                        // Timer: Every second, set the volume value from
                        // the widget in the Music App
                        .onReceive(timers.$first) { _ in
                            // Was the volume changed in the Music App?
                            let musicAppVol
                            = self.musicModel.musicAppBridge.soundVolume
                            let widgetVol = volumeSliderData.sliderValue
                            
                            // Adjust the slider in the widget if
                            // 1. The volume was changed in the Music App
                            // 2. The timer is not paused (i.e., the slider
                            //    in the widget is not being dragged)
                            // 3. The player is currently playing (if stopped,
                            //    the volume returned is 0, not the actual value)
                            if musicAppVol != widgetVol as NSNumber
                                && self.timerPaused == false
                                && musicModel.musicState.status == .playing {
                                // Adjust the slider in the widget
                                volumeSliderData.sliderValue
                                    = Double(truncating: musicAppVol)
                            }
                        }
                    }
                    
                    ToolbarItem {
                        Button(action: {
                            // Volume = 100
                            volumeSliderData.sliderValue = 100
                            musicModel.musicAppBridge.soundVolume =
                            NSNumber(value: 100)
                        }, label: {
                            Image(systemName: "speaker.wave.3.fill")
                        })
                        .frame(width: 20)
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)  // No title bar
        .windowResizability(.contentSize)  // Window size cannot be changed
    }
}
