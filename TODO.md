# To-Do List

## Completed ✅
- [x] Handle case when player is stopped (not just paused)
- [x] Hide heart and stars and show message if track is not in the library
- [x] Adjust volume slider when changed in the Music app
- [x] Update rating in widget when changed in the Music app
- [x] Reduce CPU usage
  - It's caused by timers: This becomes clear when changing from 1 and 2 seconds to 10 and 20.
  - SlidingText is no longer used. The timer required for it consumes too much power.
  - Timer for slider changed from 1s to 5s
- [x] Buttons for Repeat/Shuffle
- [x] Display play count, last played, and date added
- [x] Save album cover to clipboard only

## Pending 🔧
- [ ] Add current track to playlist
- [ ] Add "+" button in top right to add track to library
- [ ] Implement artwork fallback for streamed (non-library) tracks over iTunes Search API
