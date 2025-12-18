//
//  ContentView.swift
//  Music Widget
//
//  Created by Corvin Gröning on 04.07.22.
//

import SwiftUI
import Combine
import AudioToolbox  // for AudioServicesPlaySystemSound
import AVFAudio


struct ContentView: View {
    /// Height of the window in which the ContentView is displayed.
    let windowHeight: CGFloat = 100
    
    /// Instance of MusicModel (Singleton)
    @EnvironmentObject var musicModel: MusicModel
    
    /// Instance of VolumeSliderData (Singleton)
    @EnvironmentObject var volumeSliderData: VolumeSliderData
    
    /// The slider value for the Player Position Slider.
    @State var sliderValue: CGFloat = 0
    
    /// Indicates Player Position Slider is being dragged/paused.
    @State var timerPaused: Bool = false
    
    /// Duration of the song, used to calculate the player position.
    @State var songDuration: CGFloat = 1
    
    /// Instance of Timers, used to update the player position slider
    @StateObject private var timers = Timers.shared
    
    /// Indicates whether the info button is activated
    @AppStorage("isInfoButtonActivated") var isInfoButtonActivated: Bool = false
    
    /// Indicates whether the shuffle is activated
    @State var shuffleEnabled: Bool = false
    
    /// Current song repeat setting
    /// (kRp0 = no repeat, kAll = repeat all songs, kRp1 = repeat current song)
    @State var songRepeat: String = "kRp0"
    
    
    // Test:
    @State private var showPlaylistPicker = false
    @State private var selection = " "
    
    
    var body: some View {
        HStack (alignment: .top, spacing: 0) {
            // Cover/Buttons on the cover
            ZStack (alignment: Alignment(horizontal: .trailing, vertical: .top))
            {
                // Cover
                musicModel.trackInfo.cover
                .resizable()
                .frame(width: windowHeight, height: windowHeight)
                // Darkening the cover from top right to bottom left
                // https://designcode.io/swiftui-handbook-mask-and-transparency
                .mask(LinearGradient(gradient: Gradient(
                    colors: [.black, .black, .black, .clear]),
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                ))
                
                VStack {
                    HStack {
                        Spacer()
                        
                        // Button that shows a checkmark if the track is in the
                        // library or a plus to add the track to the library
                        Button(action: { },
                               label: { Image(
                                   systemName: musicModel.songInLibrary
                                   ? "checkmark.circle" : "minus.circle")
                        })
                        .help(
                            musicModel.songInLibrary ?
                            "The current title has been added to the library." :
                            "The current title has NOT been added to the library."
                        )
                        .buttonStyle(.borderedProminent)
                        .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                        .padding(.top, 4)
                    }
                    
                    Spacer()
                    
                    // Additional information about the track, displayed when
                    // activated by clicking on the info icon
                    VStack {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                                .frame(width: 15)
                                .font(.system(size: 11))
                                .padding(.leading, 5)
                                .help("Date added")
                            Text(musicModel.trackInfo.dateAdded)
                                .font(Font.system(size: 11))
                            Spacer()
                        }
                        HStack {
                            Image(systemName: "play")
                                .frame(width: 15)
                                .font(.system(size: 11))
                                .padding(.leading, 5)
                                .help("Date played")
                            Text(musicModel.trackInfo.datePlayed)
                                .font(Font.system(size: 11))
                            Spacer()
                        }
                        HStack {
                            Image(systemName: "number")
                                .frame(width: 15)
                                .font(.system(size: 11))
                                .padding(.leading, 5)
                                .help("Play count")
                            Text(musicModel.trackInfo.playCount)
                                .font(Font.system(size: 11))
                            Spacer()
                        }
                    }
                    .background(Color(nsColor: NSColor.windowBackgroundColor))
                    .opacity((self.isInfoButtonActivated) ? 0.8 : 0.0)
                    .padding([.bottom], 2)
                }
                
                
            }
            .padding(0)
            .padding(.leading, -2)
            .frame(width: windowHeight, height: windowHeight)
            
            VStack (alignment: .center) {
                // Title, Artist and Album
                HStack (alignment: .bottom) {
                    Image(systemName: "music.note")
                        .frame(width: 15)
                        .font(.system(size: 11))
                        .help("Title")
                    Text(musicModel.trackInfo.name).font(Font.system(size: 11))
                        .help(musicModel.trackInfo.name)
// The required timer for SlidingText uses too much CPU power/energy
//                    GeometryReader(content: { geometry in
//                        SlidingText(geometryProxy: geometry,
//                                    text: musicModel.trackInfo.name,
//                                    fontSize: 11, boldFont: true)
//                    })
                    Spacer()
                }
                .frame(height: 14)
                HStack {
                    Image(systemName: "person.fill")
                        .frame(width: 15)
                        .font(.system(size: 11))
                        .help("Artist")
                    Text(musicModel.trackInfo.artist).font(Font.system(size: 11))
                        .help(musicModel.trackInfo.artist)
// The required timer for SlidingText uses too much CPU power/energy
//                        GeometryReader(content: { geometry in
//                            SlidingText(geometryProxy: geometry,
//                                        text: musicModel.trackInfo.artist,
//                                        fontSize: 11, boldFont: false)
//                        })
                    Spacer()
                }
                .frame(height: 14)
                .padding(.top, -9)
                HStack {
                    Image(systemName: "opticaldisc")
                        .frame(width: 15)
                        .font(.system(size: 11))
                        .help("Album")
                    Text(musicModel.trackInfo.album).font(Font.system(size: 11))
                        .help(musicModel.trackInfo.album)
// The required timer for SlidingText uses too much CPU power/energy
//                    GeometryReader(content: { geometry in
//                        SlidingText(geometryProxy: geometry,
//                                    text: musicModel.trackInfo.album,
//                                    fontSize: 11, boldFont: false)
//                    })
                    Spacer()
                }
                .frame(height: 14)
                .padding(.top, -9)
                
                // Test: Picker via ZStack
                // (ZStack can be removed when Picker is removed)
                ZStack {
                    HStack (alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/) {
                        ZStack {
                            // Message displayed when heart and stars
                            // are hidden
                            Text("[Song not in library.]")
                                .font(Font.system(size: 10)) //.bold()
                                .lineSpacing(0)
                                .opacity(musicModel.songInLibrary ? 0 : 1)
                            
                            // Heart and stars
                            HStack {
                                // Heart
                                let loved = musicModel.trackInfo.loved
                                Button(action: {
                                    musicModel.toggleLoved()
                                }, label: {
                                    Image(systemName: loved ? "heart.fill" : "heart")
                                        .foregroundStyle(.red)
                                })
                                .buttonStyle(.plain)
                                //.font(.system(size: 8))
                                //.frame(width: 10, height: 10)
                                .padding(.trailing, 5)
                                
                                // 5 Buttons for the stars
                                ForEach(1..<6) { stars in
                                    RatingButton(starNumber: stars,
                                                 trackRating: musicModel.trackInfo.rating,
                                                 timer: timers.$first)
                                    .buttonStyle(.plain)
                                    .foregroundStyle(.blue)
                                    .padding(.trailing, (stars==5) ? 5 : -6)
                                }
                            }
                            // Hide heart and stars if the song is not in
                            // the library, i.e. accessed via Apple Music
                            .opacity(musicModel.songInLibrary ? 1 : 0)
                        }
                        
                        Spacer()
                        
                        // End Track Button
                        Button(action: {
                            let endPos = NSNumber(value: songDuration - 1)
                            musicModel.musicAppBridge.playerPosition = endPos
                        }, label: {
                            Image(systemName: "arrow.right.to.line.compact")
                        })
                        .help("End track = skip to next track but increase the " +
                              "play count of the current track.")
                        .buttonStyle(.plain)
                        //                    .padding([.top], -15)
                        
                        // Shuffle-Button
                        Button(action: {
                            self.musicModel.musicAppBridge.toggleShuffle()
                            self.shuffleEnabled.toggle()
                        },
                               label: { Image(systemName: "shuffle") })
                        .buttonStyle(.plain)
                        .foregroundStyle(
                            (self.shuffleEnabled) ?
                                Color(red: 0, green: 0.5, blue: 0) : .primary
                        )
                        .onAppear{
                            self.shuffleEnabled = self.musicModel.musicAppBridge
                                                      .shuffleEnabled as! Bool
                        }
                        .onReceive(timers.$second) { _ in
                            self.shuffleEnabled = self.musicModel.musicAppBridge
                                                      .shuffleEnabled as! Bool
                        }
                        //                    .padding([.top], -15)
                        
                        
                        // Repeat-Button
                        Button(
                            action: {
                                self.musicModel.musicAppBridge.toggleSongRepeat()
                                if self.songRepeat == "kRp0"
                                || self.songRepeat == "kRpO" {
                                    self.songRepeat = "kAll"
                                    print(self.songRepeat)
                                } else if self.songRepeat == "kAll" {
                                    self.songRepeat = "kRp1"
                                    print(self.songRepeat)
                                } else {
                                    self.songRepeat = "kRp0"
                                    print(self.songRepeat)
                                }
                            },
                            label: {
                                Image(systemName: (self.songRepeat == "kRp1") ?
                                                  "repeat.1" : "repeat" )
                            }
                        )
                        .buttonStyle(.plain)
                        .foregroundStyle(
                            (self.songRepeat == "kAll" || self.songRepeat == "kRp1") ?
                            Color(red: 0, green: 0.5, blue: 0) : .primary)
                        .onAppear{
                            self.songRepeat = self.musicModel.musicAppBridge
                                .songRepeat.stringValue ?? "kRp0"
                        }
                        .onReceive(timers.$second) { _ in
                            self.songRepeat = self.musicModel.musicAppBridge
                                .songRepeat.stringValue ?? "kRp0"
                        }
                        //                    .padding([.top], -15)
                        
                        // Add to playlist-Button
                        //                    Button(action: { },
                        //                           label: { Image(systemName: "list.triangle") })
                        //                    .buttonStyle(.plain)
                        
                        // Info-Button
                        Button(action: { self.isInfoButtonActivated.toggle() },
                               label: { Image(systemName: "info.circle") })
                        .buttonStyle(.plain)
                        .foregroundStyle(
                            (self.isInfoButtonActivated) ?
                            Color(red: 0, green: 0.5, blue: 0) : .primary
                        )
                        
                        
                        // Playlist-Button
                        Button(action: { self.showPlaylistPicker.toggle() },
                               label: { Image(systemName: "music.note.list") })
                        .buttonStyle(.plain)
                        //                    .padding([.top], -15)
                    }.padding([.top], -5)
                        .padding([.bottom], -10)
                        .padding([.trailing], 5)
                        .opacity(self.showPlaylistPicker ? 0 : 1)
                    
                    // Test: Picker
                    Picker("Playlist:", selection: $selection) {
                        //                        Text(" ").tag(nil as String?)
                        ForEach([" ", "One", "Two", "Three"], id: \.self) {
                            Text($0)
                        }
                    }
                    .onChange(of: selection) { oldValue, newValue in
                        print("New selection: \(newValue)")
                        performAction(for: newValue)
                        self.showPlaylistPicker.toggle()
                    }
                    .padding([.top], -5)
                    .padding([.bottom], -10)
                    .padding([.trailing], 5)
                    .opacity(self.showPlaylistPicker ? 1 : 0)
                }
                
                //                // Slider for Player Position
                //                Slider(value: $sliderValue, in: 0...((songDuration > 0) ? songDuration : 1), step: 1,
                //                       onEditingChanged: {
                //                    sliderBeingDragged in
                //
                //                    // Pause timer while slider is being moved
                //                    timerPaused = sliderBeingDragged ? true : false
                //
                //                    // Only change the player position if the change
                //                    // is greater than 2%. This also avoids the jerky
                //                    // sound playback when pressing the mouse button
                //                    let plPos = musicModel.musicAppBridge.playerPosition
                //
                //                    if abs(sliderValue / Double(truncating: plPos) - 1) > 0.02 {
                //                        musicModel.musicAppBridge.playerPosition =
                //                        NSNumber(value: sliderValue)
                //                    }
                //                })
                //                .onReceive(timers.$first) { _ in
                //                    if !timerPaused {
                //                        self.sliderValue = Double(musicModel.getPlayerPosition())
                //
                //                        // Song Duration is sometimes 0 when starting the app
                //                        // for unexplained reasons, hence this workaround
                //                        self.songDuration = Double(musicModel.getDuration())
                //
                //                        // Update favorite and star rating, in case
                //                        // it was changed in the Music app
                //                        //musicModel.getTrackInfo()
                //                        //musicModel.getTrackInfo()
                //                        musicModel.updatedLovedAndRating()
                //                    }
                //                }
                //                .padding(0)
                //                .frame(height: 19)
                
                
                ZStack {
                    VStack {
                        CustomSlider(value: $sliderValue, maxValue: songDuration)
                            .onReceive(timers.$first) { _ in
                                if !timerPaused {
                                    self.sliderValue
                                        = Double(musicModel.getPlayerPosition())
                                    
                                    // Song Duration is sometimes 0 when
                                    // starting the app for unexplained reasons,
                                    // hence this workaround
                                    self.songDuration
                                        = Double(musicModel.getDuration())
                                    
                                    // Update favorite and star rating, in case
                                    // it was changed in the Music app
                                    //musicModel.getTrackInfo()
                                    //musicModel.getTrackInfo()
                                    musicModel.updatedLovedAndRating()
                                }
                            }
                            .opacity(0.7)
                            .frame(height: 10)
                            .padding(.trailing, 4)
                        
                        // Player-Position and Duration
                        let position = Track.formatSeconds(Int(sliderValue))
                        let duration = musicModel.trackInfo.durationFormatted
                        let remaining = Track.formatSeconds(
                            Int(sliderValue) - musicModel.trackInfo.duration)
                        
                        // Workaround for the case when the player is stopped
                        let progress = String(
                            Int(
                                (sliderValue / ((songDuration > 0) ? songDuration : 1)) * 100
                            )
                        )
                        
                        HStack {
                            Text("\(position) (\(remaining))")
                                .frame(minWidth: 100,
                                       maxWidth: .infinity,
                                       alignment: .leading)
                                .font(.system(size: 10))
                            Text("\(progress) %")
                                .frame(maxWidth: 50,
                                       alignment: .center)
                                .font(.system(size: 10))
                            Text(duration)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .font(.system(size: 10))
                                .padding(.trailing, 5)
                        }
                        .padding(.top, -5)
                        .padding(.trailing, 10)
                    }
                    .padding(0)
                    .opacity((songDuration == 1) ? 0 : 1.0)
                    
                    Text("Loading player position...")
                        .opacity((songDuration == 1) ? 1 : 0)
                }
                .padding([.top], 7)
                
            }
            .padding(.leading, 5)
            .padding(.trailing, 5)
            .padding(.bottom, 5)
            // Blurred cover as background
            .background(
                musicModel.trackInfo.cover
                    .resizable()
                    .frame(height: 115)
                    .blur(radius: 20, opaque: false)
                    .opacity(0.5)
            )
        }
        .padding(0)
        .disabled(!musicModel.musicState.running)
        .opacity(musicModel.musicState.running ? 1 : 0.5)
        .task { await musicModel.getMusicState() }
        .onAppear { timers.start() }
        .onDisappear { timers.stop() }
    }
}





// Test:
func performAction(for selection: String) {
    // Execute the desired action here
    print("Executing action for \(selection)")
}





struct ContentView_Previews: PreviewProvider {
    // Instance of MusicModel (Singleton)
    static let musicModel: MusicModel = .shared
    static let volumeSliderData: VolumeSliderData = .shared
    
    static var previews: some View {
        ContentView(sliderValue: 0)
            .environmentObject(musicModel)
            .environmentObject(volumeSliderData)
            .frame(width: 385)
    }
}


/// CustomView for the rating/star buttons. The button flashes when
/// the current track has not been rated yet and the track progress
/// is >= 80%.
/// - Parameter starNumber: Number of stars this button represents
/// - Parameter trackRating: Rating (0-5) of the current track
/// - Parameter timer: Publisher-Object of the timer (required so that
/// the button can flash)
struct RatingButton: View {
    let starNumber: Int
    let trackRating: Int
    let timer: Published<Int>.Publisher
    
    @State var appJustStarted: Bool = true
    @State var showWarningColor: Bool = false
    
    // Audio player to play warning sound when title is not yet rated
    @State var audioPlayer: AVAudioPlayer?
    
    /// Indicates whether the warning for the case that the track is about to
    /// end, but has not yet been rated, should be disabled
    @AppStorage("songNotRatedWarningDisabled")
    var songNotRatedWarningDisabled: Bool = false
    
    var body: some View {
        Button(action: {
            // Set track rating
            MusicModel.shared.setRating(rating: starNumber)
        }, label: {
            Image(systemName: trackRating >= starNumber ? "star.fill" : "star")
                .foregroundStyle(.blue)
        })
        .foregroundColor(self.showWarningColor ? .red : .none)
        .onAppear {
            // Prepare audio player in case a notification sound for missing
            // rating should be played
            if let audio = NSDataAsset(name: "Audiio_MobilePhoneChime2") {
                do {
                    audioPlayer = try AVAudioPlayer(data: audio.data)
                    audioPlayer?.volume = 0.3
                } catch {
                    print("Error: \(error)")
                }
            }
        }
        .onReceive(timer) { _ in
            // Determine track progress
            let trackProgess: Double =
            Double(truncating: MusicModel.shared.musicAppBridge.playerPosition)
            / Double(MusicModel.shared.trackInfo.duration)
            
            // Skip the first timer step (have to wait
            // until MusicModel.shared.trackInfo.rating is set, otherwise
            // a malfunction will occur)
            if self.appJustStarted {
                self.appJustStarted = false
            } else {
                // Should the button flash?
                if MusicModel.shared.trackInfo.rating == 0  // no rating?
                    && trackProgess >= 0.8  // Track progress >= 80%
                    && !songNotRatedWarningDisabled {
                    self.showWarningColor.toggle()
                    
                    // Play notification sound due to missing rating
                    //                    AudioServicesPlaySystemSound(1209)
                    audioPlayer?.play()
                } else {
                    self.showWarningColor = false
                }
            }
        }
    }
}


/// Alternative to Text(): If the passed string is wider than the space in the
/// UI, it is animated (it runs from left to right and back again).
struct SlidingText: View {
    // GeometryProxy in which the text is located (contains available width)
    let geometryProxy: GeometryProxy
    
    // Text whose width is to be measured
    let text: String
    
    // Font size and bold yes/no
    let fontSize: CGFloat
    let boldFont: Bool
    
    // Settings for sliding
    @State private var animateSliding: Bool = false
    private let slideDuration: Double = 1.8
    // @StateObject private var timers = Timers()
    @StateObject private var timers = Timers.shared
    
    var body: some View {
        ZStack(alignment: .leading, content: {
            VStack {
                if boldFont {
                    Text(text).font(Font.system(size: fontSize)).bold()
                } else {
                    Text(text).font(Font.system(size: fontSize))
                }
            }
            .fixedSize()
            .frame(width: geometryProxy.size.width,
                   // The alignment should only be changed if sliding
                   // is necessary
                   alignment:
                       (animateSliding && text.widthOfString(usingFont:
                           NSFont.systemFont(ofSize: fontSize)) >
                           geometryProxy.size.width
                       ) ? .trailing : .leading)
            .clipped()
            .animation(Animation.linear(duration: slideDuration),
                       value: self.animateSliding)
            .onReceive(timers.$second) { _ in
                // Only animate if there is not enough space to display the
                // complete text
                let spaceRequired = text.widthOfString(
                    usingFont: NSFont.systemFont(ofSize: fontSize)
                )
                let spaceAvailable = geometryProxy.size.width
                
                if spaceRequired > spaceAvailable {
                    self.animateSliding.toggle()
                }
            }
        })
        .frame(width: self.geometryProxy.size.width,
               height: self.geometryProxy.size.height)
        .clipShape(Rectangle())
        .onAppear { timers.start()  }
        .onDisappear { timers.stop() }
    }
}


extension String {
    /// Returns the width in pixels that a text requires in the UI.
    ///
    /// ```
    /// // Width of a text in system font and font size 14
    /// let width = text.widthOfString(usingFont: NSFont.systemFont(ofSize: 14))
    /// ```
    ///
    /// - Parameter font: Instance of NSFont, which contains font and size
    /// - Warning: Care must be taken to ensure that the correct font
    /// and size are passed.
    /// - Note: For iOS, UIFont must be used instead of NSFont, which
    /// requires importing UIKit.
    /// - Returns: Width of the text in the UI
    func widthOfString(usingFont font: NSFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.width
    }
}

/// ViewModel to allow multiple timers.
final class Timers: ObservableObject {
    /// Singleton: Instance of this class (constructor must be private)
    static let shared = Timers()
    
    @Published private(set) var first = 0
    @Published private(set) var second = 0
    private var subscriptions: Set<AnyCancellable> = []
    
    
    private init() { }
    
    /// Starts all timers
    /// Currently the following timers are available:
    ///
    /// - first: every 5 seconds, intended for Player Position Slider
    /// - second: every 2 seconds, intended for SlidingText
    ///
    /// A tolerance of 1 s is used to reduce CPU usage
    /// (the system has the possibility of timer coalescing, the
    /// CPU can remain more in idle,
    /// see https://www.hackingwithswift.com/books/ios-swiftui/triggering-events-repeatedly-using-a-timer)
    func start() {
        Timer.publish(every: 5, tolerance: 1, on: .main, in: .common)
            .autoconnect()
            .scan(0) { accumulated, _ in accumulated + 1 }
            .assign(to: \.first, on: self)
            .store(in: &subscriptions)
        Timer.publish(every: 2, tolerance: 1, on: .main, in: .common)
            .autoconnect()
            .scan(0) { accumulated, _ in accumulated + 1 }
            .assign(to: \.second, on: self)
            .store(in: &subscriptions)
    }
    
    /// Deletes all timers
    func stop() {
        subscriptions.removeAll()
    }
}

/// Custom Slider for the Player Position Slider
struct CustomSlider: View {
    /// EnvironmentObject for the MusicModel
    @EnvironmentObject var musicModel: MusicModel
    
    /// The value of the slider which is bound to the MusicModel
    @Binding var value: CGFloat
    
    /// The minimum value of the slider - usually 0
    private var minValue: CGFloat
    
    /// The maximum value of the slider - usually song duration
    private var maxValue: CGFloat
    
    /// Radius of the thumb which is the red circle
    private let thumbRadius: CGFloat = 12
    

    init(value: Binding<CGFloat>, maxValue: CGFloat) {
        self._value = value
        self.minValue = 0
        self.maxValue = maxValue
    }
    var body: some View {
        GeometryReader{ geometry in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .foregroundColor(Color.black.opacity(0.3))
                
                // Progress
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: .init(colors: [Color.blue, Color.red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: geometry.size.width
                                   * (CGFloat(value) / CGFloat(maxValue))
                    )
                    .contentShape(.capsule)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(.white, in: Capsule().stroke(style: .init()))
                
                // 25% marking
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 2, height: 6, alignment: .center)
                    .offset(x: geometry.size.width / 4)
                
                // 50% marking
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 2, height: 6, alignment: .center)
                    .offset(x: geometry.size.width / 2)
                
                // 75% marking
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 2, height: 6, alignment: .center)
                    .offset(x: geometry.size.width / 4 * 3)
                
                // Thumb
                Circle()
                    .fill(Color.red.opacity(0.8))
                    .stroke(Color.black.opacity(0.6), lineWidth: 2)
                    .frame(width: thumbRadius * 2)
                    .offset(
                        x: geometry.size.width
                               * (CGFloat(value) / CGFloat(maxValue))
                               - thumbRadius
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged({ gesture in
                                updateSliderValue(with: gesture, in: geometry)
                                
                                // Only change the player position if the change
                                // is greater than 5%. This avoids the jerky
                                // sound playback when pressing the mouse button
                                let plPos = musicModel.musicAppBridge
                                                .playerPosition
                                
                                musicModel.musicAppBridge.playerPosition =
                                    NSNumber(value: value)
                            })
                    )
            }
        }
    }
    
    
    
    /// Updates the slider value when the thumb is dragging
    private func updateSliderValue(
        with gesture: DragGesture.Value, in geometry: GeometryProxy
    ) {
        var newValue: CGFloat
        newValue = (gesture.location.x / geometry.size.width) * maxValue
        
        if newValue < 0 {
            value = 0
        } else if newValue > maxValue {
            value = maxValue
        } else {
            value = newValue
        }
    }
}
