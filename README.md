# Swift Apple Podcasts

Read Apple Podcasts from Swift — shows, episodes, what was listened to (on any device, through
iCloud), and what was said, from Apple's own transcripts — from Podcasts' store, not by
driving the app.

```swift
import ApplePodcasts

let store = try PodcastsStore()
for show in store.shows() { print(show.title, show.isFollowed, show.feed ?? "") }
let started = store.episodes().filter { $0.state == .inProgress }
for line in try store.transcript(of: started[0]) { print(line.start, line.speaker ?? "", line.text) }
store.searchTranscripts("interest rates")     // the line, and the moment it was said
```

## Where Podcasts keeps it

Measured on macOS 27 with a library the user followed and listened to for the purpose:

- **The store** is `Documents/MTLibrary.sqlite` in the `243LU875E5.groups.com.apple.podcasts`
  container, a Core Data store Podcasts writes as it plays, so it is read as a private snapshot
  (with its write-ahead log) through [swift-sqlite-reader](https://github.com/arraypress/swift-sqlite-reader).
  Shows are `ZMTPODCAST` (the newer `ZUPDATEDFEEDURL` wins over `ZFEEDURL`); episodes are
  `ZMTEPISODE`, their length is in `ZMTMEDIAENCLOSURE` (the episode's current enclosure) and their
  description in `ZMTEPISODEDESCRIPTION`. The app reading it needs Full Disk Access.
- **Play state**: `ZPLAYSTATE` 0 for an episode not started (1,316 of 1,322 on the measured
  library), 1 for one with a listening position (`ZPLAYHEAD`, seconds); `ZHASBEENPLAYED` or
  `ZMARKASPLAYED` reads as played. Other states are reported as `other` until measured.
  `ZLASTDATEPLAYED` carries listening from other devices too.
- **Transcripts** are Apple's TTML, cached under `Library/Cache/Assets/TTML/…/transcript_<store
  id>.ttml-<store id>.ttml` for episodes played on this Mac (1,286 episodes named one; 4 were
  cached). Each `<p>` is a speaker's turn (`ttm:agent="SPEAKER_1"`) of timed sentence and word
  spans; a line here is a sentence with its speaker, and words outside a sentence make a line of
  their own. A 78-minute episode: 1,424 lines, three speakers, read in 0.3 s.

## Automating Podcasts

Nothing here writes. Podcasts has no AppleScript; its Shortcuts actions play an episode, search
the catalogue, follow a show, get a show's episodes and open one (`shortcut actions podcast`).

## Tested

6 tests against a synthetic store with the real tables and a transcript written the way Apple's
are — no one's library is read. Every rule broken on purpose is caught (18 of 18 mutations).
Checked by hand on the measured library: shows, follows, episode counts, the three episodes in
progress, a transcript and a search.

## Requirements

macOS 14 or later; Swift 6.2. Full Disk Access for the app reading it.

## License

MIT — see [LICENSE](LICENSE).
