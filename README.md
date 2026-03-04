# Music Widget for Apple Music (macOS)

Music Widget is a lightweight and always-on-top controller for Apple Music on macOS. Designed to complement your desktop environment, it gives you instant access to playback controls, track details, and library management without switching windows — all in a compact, customizable interface.

![Screenshot](screenshot_small.png)

---

## 🎵 Features

- 🎧 Always-on-top mini player for Apple Music
- ⏯ Playback controls: play, pause, skip
- ⭐ Mark songs as favorites and set star ratings
- ⌨️ Keyboard shortcuts for quick control without switching focus
- 🖼 Display album cover and track info
- 📊 View play count, last played, and added date
- 🔁 Shuffle and repeat toggle
- 🎚 Volume and progress bar
- 📌 Toggle sound notifications
- 🔒 Minimal footprint, designed to stay out of the way
- ➕ Add tracks to playlists (under development)

---

## ⌨️ Keyboard shortcuts

- F1: Set star rating to 1
- F2: Set star rating to 2
- F3: Set star rating to 3
- F4: Set star rating to 4
- F5: Set star rating to 5
- F6: Toggle Loved (Favorite)
- F7: Previous Track
- F8: Play/Pause
- F9: Next Track
- F10: Toggle Mute
- F11: Volume Down
- F12: Volume Up

---

## 🖥 Requirements

- macOS 11.0 or later
- Apple Music (pre-installed with macOS)
- Swift + AppKit (for development)

---

## 🛠 Installation

### Build from Source

```zsh
git clone https://github.com/cgroening/AppleMusicWidget.git
cd music-widget
open MusicWidget.xcodeproj
```

- Build and run using Xcode.

---

## ↗️ Distributing the app

There are several ways to distribute the built `.app` file to other Macs. Choose the distribution method depending on your target audience and intended use case.

1. Simple Copy of the `.app`: When you only need to share the app for local testing or personal use
2. Archive & Export: When you want a cleaner, more professional build for sharing with others
3. Code Signing & Notarization: When you plan to distribute the app publicly and want to avoid macOS security warnings

In the following, the methods are explained in detail.

### Build for Local Testing (Simple Copy of the .app)

1. In Xcode, select the Release build configuration:
   - Product → Scheme → Edit Scheme
   - Under *Run*, set *Build Configuration* to *Release*
2. Build the app: Product → Build
3. Reveal the compiled app in Finder:
   - Product → Show Build Folder in Finder
   - Navigate into → Build/Products/Release/
   - The .app here (e.g., MusicWidget.app) is the runnable app bundle.
4. Copy this `.app` file to another Mac using AirDrop, USB, cloud storage or file share.

⚠️ Because this app isn't signed or notarized yet, macOS Gatekeeper may block it on other Devices. Users can bypass this by following this guide: [Open a Mac app from an unknown developer – Apple Support](https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unknown-developer-mh40616/mac).

### Archive & Export (Better for Distribution)

For more polished output:

1. In Xcode, choose: Product → Archive
2. Xcode Organizer opens with your archive.
3. Click Distribute App.
4. Choose Export → Copy App (or similar option)
   This produces an exported .app bundle you can share.
5. Optionally compress it (`.zip`) before uploading or sending.

This method packages the app cleanly and is generally preferred over copying the raw build folder.

### Code Signing & Notarization (For Clean macOS Launch)

To avoid Gatekeeper warnings on other Macs:

1. Join the Apple Developer Program and generate a Developer ID Application certificate.
2. In Xcode:
   - Enable Signing & Capabilities
   - Select your Team and let Xcode manage signing
3. Build or archive again with signing enabled.
4. Upload the signed build for notarization via Xcode or the altool/notarytool CLI.
5. Once notarized, you'll get a stapled app that can be opened.

Follow this guide for a more detailed description:

[Notarizing macOS software before distribution | Apple Developer Documentation](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
Signed & notarized builds are ideal if you plan to distribute widely.

---

## 🙌 Acknowledgements

- Built using Swift and AppKit.
- Inspired by Apple's Music API and minimalist player designs.

---

## 🔗 Links

- [Apple Music API](https://developer.apple.com/documentation/applemusicapi)
- [Swift Documentation](https://swift.org/documentation/)
