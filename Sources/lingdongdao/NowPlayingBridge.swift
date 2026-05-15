import Foundation

@MainActor
protocol PlaybackSource: AnyObject {
    func start(_ onSnapshot: @escaping @MainActor (NowPlayingSnapshot) -> Void)
    func stop()
}

@MainActor
protocol LyricsSource {
    func lyrics(for track: NowPlayingTrack) async throws -> [TimedLyricLine]
}

@MainActor
protocol LyricsCache {
    func lyrics(for trackID: String) -> [TimedLyricLine]?
    func store(_ lyrics: [TimedLyricLine], for trackID: String)
}

struct MockLyricsSource: LyricsSource {
    func lyrics(for track: NowPlayingTrack) async throws -> [TimedLyricLine] {
        DemoLibrary.lyrics(for: track.id)
    }
}

@MainActor
final class InMemoryLyricsCache: LyricsCache {
    private var storage: [String: [TimedLyricLine]] = [:]

    func lyrics(for trackID: String) -> [TimedLyricLine]? {
        storage[trackID]
    }

    func store(_ lyrics: [TimedLyricLine], for trackID: String) {
        storage[trackID] = lyrics
    }
}

@MainActor
final class MockPlaybackSource: PlaybackSource, ObservableObject {
    private var timer: Timer?
    private var progress: TimeInterval = 0
    private var trackIndex = 0
    private let playlist = DemoLibrary.playlist

    func start(_ onSnapshot: @escaping @MainActor (NowPlayingSnapshot) -> Void) {
        timer?.invalidate()
        progress = 0
        pushSnapshot(onSnapshot)

        timer = Timer.scheduledTimer(withTimeInterval: 0.30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let currentTrack = self.playlist[self.trackIndex]
                self.progress += 0.30

                if self.progress >= currentTrack.duration {
                    self.trackIndex = (self.trackIndex + 1) % self.playlist.count
                    self.progress = 0
                }

                onSnapshot(
                    NowPlayingSnapshot(
                        track: self.playlist[self.trackIndex],
                        lyrics: DemoLibrary.lyrics(for: self.playlist[self.trackIndex].id),
                        progress: self.progress,
                        isPlaying: true
                    )
                )
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func pushSnapshot(_ onSnapshot: @escaping @MainActor (NowPlayingSnapshot) -> Void) {
        let track = playlist[trackIndex]
        onSnapshot(
            NowPlayingSnapshot(
                track: track,
                lyrics: DemoLibrary.lyrics(for: track.id),
                progress: progress,
                isPlaying: true
            )
        )
    }
}

enum DemoLibrary {
    static let playlist: [NowPlayingTrack] = [
        NowPlayingTrack(
            id: "track.blink",
            title: "BLiNK",
            artist: "MONKEY MAJIK × UQiYO",
            album: "COLLABO RATED",
            accentColorHex: "#D81B60",
            secondaryColorHex: "#FF8BA7",
            duration: 38,
            artworkSymbol: "waveform.and.mic"
        ),
        NowPlayingTrack(
            id: "track.aperture",
            title: "Aperture",
            artist: "Tycho",
            album: "Simulcast",
            accentColorHex: "#53A6FF",
            secondaryColorHex: "#8FE3FF",
            duration: 34,
            artworkSymbol: "sparkles.tv"
        )
    ]

    static func lyrics(for trackID: String) -> [TimedLyricLine] {
        switch trackID {
        case "track.aperture":
            return [
                .init(startTime: 0, endTime: 4, text: "Signal blooms under glass skies", translation: "信号在玻璃色天空下舒展"),
                .init(startTime: 4, endTime: 8, text: "Every pulse bends into blue", translation: "每一次脉冲都弯进蓝色里"),
                .init(startTime: 8, endTime: 13, text: "Hold the light before it drifts", translation: "在它漂走之前先握住这道光"),
                .init(startTime: 13, endTime: 18, text: "We are silhouettes in motion", translation: "我们是运动中的剪影"),
                .init(startTime: 18, endTime: 24, text: "Nothing breaks, it only opens", translation: "没有什么碎裂，只是慢慢打开"),
                .init(startTime: 24, endTime: 29, text: "Stay until the color settles", translation: "留下来，直到颜色重新安静"),
                .init(startTime: 29, endTime: 34, text: "A quiet room of afterglow", translation: "像余晖后的安静房间")
            ]
        default:
            return [
                .init(startTime: 0, endTime: 4, text: "I'm lost without you", translation: "没有你我迷失了方向"),
                .init(startTime: 4, endTime: 8, text: "You will learn", translation: "你会明白的"),
                .init(startTime: 8, endTime: 13, text: "Don't let it stop", translation: "不要让它停止"),
                .init(startTime: 13, endTime: 18, text: "Best things in life on the memory shore", translation: "生命中最美好的事物在记忆的海岸边"),
                .init(startTime: 18, endTime: 23, text: "Keep the signal close", translation: "把这束信号留在身边"),
                .init(startTime: 23, endTime: 28, text: "Everything quiet turns alive", translation: "一切静默都会重新苏醒"),
                .init(startTime: 28, endTime: 38, text: "The night folds into another glow", translation: "夜色又折进另一层光里")
            ]
        }
    }
}
