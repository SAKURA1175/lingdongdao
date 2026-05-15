import Foundation

@MainActor
final class OverlayCoordinator {
    private let playbackSource: PlaybackSource
    private let lyricsSource: LyricsSource
    private let lyricsCache: LyricsCache
    private weak var overlayState: LyricsOverlayState?

    init(
        playbackSource: PlaybackSource,
        lyricsSource: LyricsSource,
        lyricsCache: LyricsCache,
        overlayState: LyricsOverlayState
    ) {
        self.playbackSource = playbackSource
        self.lyricsSource = lyricsSource
        self.lyricsCache = lyricsCache
        self.overlayState = overlayState
    }

    private var currentTrackID: String?
    private var currentLyrics: [TimedLyricLine] = []

    func start() {
        playbackSource.start { [weak self] snapshot in
            guard let self else { return }
            
            let track = snapshot.track
            
            if track.id != self.currentTrackID {
                self.currentTrackID = track.id
                
                // Clear old lyrics immediately when track changes
                self.currentLyrics = []
                self.overlayState?.apply(snapshot: NowPlayingSnapshot(
                    track: track,
                    lyrics: [],
                    progress: snapshot.progress,
                    isPlaying: snapshot.isPlaying
                ))
                
                // Fetch new lyrics
                Task {
                    if let cached = self.lyricsCache.lyrics(for: track.id) {
                        self.currentLyrics = cached
                    } else {
                        do {
                            let fetched = try await self.lyricsSource.lyrics(for: track)
                            self.lyricsCache.store(fetched, for: track.id)
                            self.currentLyrics = fetched
                        } catch {
                            print("Lyrics fetch error: \(error)")
                        }
                    }
                    
                    // Apply updated lyrics
                    self.overlayState?.apply(snapshot: NowPlayingSnapshot(
                        track: track,
                        lyrics: self.currentLyrics,
                        progress: snapshot.progress, // Might be slightly outdated, next tick will fix it
                        isPlaying: snapshot.isPlaying
                    ))
                }
            } else {
                // Same track, just update progress
                self.overlayState?.apply(snapshot: NowPlayingSnapshot(
                    track: track,
                    lyrics: self.currentLyrics,
                    progress: snapshot.progress,
                    isPlaying: snapshot.isPlaying
                ))
            }
        }
    }

    func stop() {
        playbackSource.stop()
    }
}
