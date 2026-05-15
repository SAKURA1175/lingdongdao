import Combine
import Foundation

enum KaraokeFillDirection: String, Codable, CaseIterable, Identifiable {
    case leading = "从左到右"
    case center = "从中向外"
    
    var id: String { rawValue }
    var label: String { rawValue }
}

@MainActor
final class OverlaySettingsStore: ObservableObject {
    private struct PersistedSettings: Codable, Equatable {
        var showIsland = true
        var showBottomLyrics = true
        var lineMode = LyricsLineMode.single
        var lyricLineSpacing = 4.0
        var lyricColorStyle = LyricsColorStyle.white
        var showTranslation = true
        var widthMode = OverlayWidthMode.adaptive
        var lyricsAlignment = LyricsTextAlignmentOption.center
        var useArtworkColors = true
        var enableTrackAnimation = true
        var hideInFullScreen = false
        var reduceMotion = false
        var verticalAnchor = OverlayVerticalAnchor.top
        var horizontalAnchor = OverlayHorizontalAnchor.center
        var islandStyle = IslandStyle.standard
        var karaokeMode = false
        var karaokeFillDirection = KaraokeFillDirection.center
    }

    private enum Storage {
        static let key = "com.lingdongdao.overlaySettings"
    }

    private let userDefaults: UserDefaults

    @Published var showIsland = true { didSet { persistIfNeeded() } }
    @Published var showBottomLyrics = true { didSet { persistIfNeeded() } }
    @Published var lineMode: LyricsLineMode = .single { didSet { persistIfNeeded() } }
    @Published var lyricLineSpacing = 4.0 { didSet { persistIfNeeded() } }
    @Published var lyricColorStyle: LyricsColorStyle = .white { didSet { persistIfNeeded() } }
    @Published var showTranslation = true { didSet { persistIfNeeded() } }
    @Published var widthMode: OverlayWidthMode = .adaptive { didSet { persistIfNeeded() } }
    @Published var lyricsAlignment: LyricsTextAlignmentOption = .center { didSet { persistIfNeeded() } }
    @Published var useArtworkColors = true { didSet { persistIfNeeded() } }
    @Published var enableTrackAnimation = true { didSet { persistIfNeeded() } }
    @Published var hideInFullScreen = false { didSet { persistIfNeeded() } }
    @Published var reduceMotion = false { didSet { persistIfNeeded() } }
    @Published var verticalAnchor: OverlayVerticalAnchor = .top { didSet { persistIfNeeded() } }
    @Published var horizontalAnchor: OverlayHorizontalAnchor = .center { didSet { persistIfNeeded() } }
    @Published var islandStyle: IslandStyle = .standard { didSet { persistIfNeeded() } }
    @Published var karaokeMode = false { didSet { persistIfNeeded() } }
    @Published var karaokeFillDirection: KaraokeFillDirection = .center { didSet { persistIfNeeded() } }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
    }

    func toggleIslandVisibility() {
        showIsland.toggle()
    }

    func toggleBottomLyrics() {
        showBottomLyrics.toggle()
    }

    func toggleTranslation() {
        showTranslation.toggle()
    }

    private func load() {
        guard let data = userDefaults.data(forKey: Storage.key),
              let persisted = try? JSONDecoder().decode(PersistedSettings.self, from: data) else {
            return
        }

        showIsland = persisted.showIsland
        showBottomLyrics = persisted.showBottomLyrics
        lineMode = persisted.lineMode
        lyricLineSpacing = persisted.lyricLineSpacing
        lyricColorStyle = persisted.lyricColorStyle
        showTranslation = persisted.showTranslation
        widthMode = persisted.widthMode
        lyricsAlignment = persisted.lyricsAlignment
        useArtworkColors = persisted.useArtworkColors
        enableTrackAnimation = persisted.enableTrackAnimation
        hideInFullScreen = persisted.hideInFullScreen
        reduceMotion = persisted.reduceMotion
        verticalAnchor = persisted.verticalAnchor
        horizontalAnchor = persisted.horizontalAnchor
        islandStyle = persisted.islandStyle
        karaokeMode = persisted.karaokeMode
        karaokeFillDirection = persisted.karaokeFillDirection
    }

    private func persistIfNeeded() {
        let persisted = PersistedSettings(
            showIsland: showIsland,
            showBottomLyrics: showBottomLyrics,
            lineMode: lineMode,
            lyricLineSpacing: lyricLineSpacing,
            lyricColorStyle: lyricColorStyle,
            showTranslation: showTranslation,
            widthMode: widthMode,
            lyricsAlignment: lyricsAlignment,
            useArtworkColors: useArtworkColors,
            enableTrackAnimation: enableTrackAnimation,
            hideInFullScreen: hideInFullScreen,
            reduceMotion: reduceMotion,
            verticalAnchor: verticalAnchor,
            horizontalAnchor: horizontalAnchor,
            islandStyle: islandStyle,
            karaokeMode: karaokeMode,
            karaokeFillDirection: karaokeFillDirection
        )

        guard let data = try? JSONEncoder().encode(persisted) else { return }
        userDefaults.set(data, forKey: Storage.key)
    }
}
