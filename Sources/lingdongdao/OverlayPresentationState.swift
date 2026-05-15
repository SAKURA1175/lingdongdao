import Foundation

enum OverlayDisplayPhase: Equatable {
    case idle
    case trackTransition
    case lyricTransition
}

@MainActor
final class OverlayPresentationState: ObservableObject {
    @Published private(set) var phase: OverlayDisplayPhase = .idle
    @Published private(set) var currentTrack = NowPlayingTrack.placeholder
    @Published private(set) var currentLine: TimedLyricLine?
    @Published private(set) var previousLine: TimedLyricLine?
    @Published private(set) var nextLine: TimedLyricLine?
    @Published private(set) var activeIndex: Int?
    @Published private(set) var progress: TimeInterval = 0
    @Published private(set) var isPlaying = true
    @Published private(set) var lyricTransitionToken = 0
    @Published private(set) var trackTransitionToken = 0

    func ingest(snapshot: NowPlayingSnapshot, animateTrackChanges: Bool) {
        progress = snapshot.progress
        isPlaying = snapshot.isPlaying

        let oldTrack = currentTrack
        let oldLine = currentLine
        let computedIndex = snapshot.lyrics.lastIndex { line in
            snapshot.progress >= line.startTime && (line.endTime == nil || snapshot.progress < line.endTime!)
        }

        activeIndex = computedIndex
        currentTrack = snapshot.track

        if let computedIndex {
            previousLine = computedIndex > 0 ? snapshot.lyrics[computedIndex - 1] : nil
            currentLine = snapshot.lyrics[computedIndex]
            nextLine = computedIndex + 1 < snapshot.lyrics.count ? snapshot.lyrics[computedIndex + 1] : nil
        } else {
            previousLine = nil
            currentLine = snapshot.lyrics.first
            nextLine = snapshot.lyrics.dropFirst().first
        }

        if oldTrack.id != snapshot.track.id, animateTrackChanges {
            trackTransitionToken += 1
            phase = .trackTransition
            settleAfterTransition()
        } else if oldLine?.id != currentLine?.id {
            lyricTransitionToken += 1
            phase = .lyricTransition
            settleAfterTransition()
        } else {
            phase = .idle
        }
    }

    private func settleAfterTransition() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 240_000_000)
            guard !Task.isCancelled else { return }
            self.phase = .idle
        }
    }
}
