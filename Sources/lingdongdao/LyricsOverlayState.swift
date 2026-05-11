import Combine
import Foundation

@MainActor
final class LyricsOverlayState: ObservableObject {
    let settings: OverlaySettingsStore
    let presentation: OverlayPresentationState

    private let themeEngine: LyricsThemeEngine
    private let layoutEngine: LyricsLayoutEngine
    private var cancellables: Set<AnyCancellable> = []

    @Published private(set) var lyrics: [TimedLyricLine] = []

    init(
        settings: OverlaySettingsStore,
        presentation: OverlayPresentationState = OverlayPresentationState(),
        themeEngine: LyricsThemeEngine = LyricsThemeEngine(),
        layoutEngine: LyricsLayoutEngine = LyricsLayoutEngine()
    ) {
        self.settings = settings
        self.presentation = presentation
        self.themeEngine = themeEngine
        self.layoutEngine = layoutEngine

        settings.objectWillChange
            .merge(with: presentation.objectWillChange)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    var nowPlaying: NowPlayingTrack { presentation.currentTrack }
    var activeLine: TimedLyricLine? { presentation.currentLine }
    var upcomingLine: TimedLyricLine? { presentation.nextLine }
    var previousLine: TimedLyricLine? { presentation.previousLine }
    var progress: TimeInterval { presentation.progress }
    var isPlaying: Bool { presentation.isPlaying }
    var activeIndex: Int? { presentation.activeIndex }
    var isExpanded: Bool { presentation.isExpanded }
    var phase: OverlayDisplayPhase { presentation.phase }
    var theme: IslandTheme { themeEngine.makeTheme(for: nowPlaying, settings: settings) }

    var layout: OverlayLayout {
        layoutEngine.makeLayout(
            track: nowPlaying,
            currentLine: activeLine,
            nextLine: upcomingLine,
            settings: settings,
            isExpanded: isExpanded
        )
    }

    func apply(snapshot: NowPlayingSnapshot) {
        lyrics = snapshot.lyrics
        presentation.ingest(snapshot: snapshot, animateTrackChanges: settings.enableTrackAnimation)
    }

    func handleHoverChange(isInside: Bool) {
        presentation.updateHover(isInside: isInside, settings: settings)
    }

    func toggleExpanded() {
        presentation.setExpanded(!presentation.isExpanded)
    }

    func setExpanded(_ expanded: Bool) {
        presentation.setExpanded(expanded)
    }
}
