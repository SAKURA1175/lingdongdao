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

    func start() {
        playbackSource.start { [weak self] snapshot in
            guard let self else { return }
            _ = self.lyricsSource
            _ = self.lyricsCache
            self.overlayState?.apply(snapshot: snapshot)
        }
    }

    func stop() {
        playbackSource.stop()
    }
}
