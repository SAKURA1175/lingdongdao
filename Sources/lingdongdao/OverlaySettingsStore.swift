import Combine
import Foundation

@MainActor
final class OverlaySettingsStore: ObservableObject {
    private struct PersistedSettings: Codable, Equatable {
        var showIsland = true
        var expandOnHover = true
        var showBottomLyrics = true
        var lineMode = LyricsLineMode.single
        var showTranslation = true
        var widthMode = OverlayWidthMode.adaptive
        var lyricsAlignment = LyricsTextAlignmentOption.center
        var useArtworkColors = true
        var enableTrackAnimation = true
        var hideInFullScreen = false
        var reduceMotion = false
    }

    private enum Storage {
        static let key = "lingdongdao.overlay.settings"
    }

    private let userDefaults: UserDefaults
    private var isBootstrapping = true

    @Published var showIsland = true { didSet { persistIfNeeded() } }
    @Published var expandOnHover = true { didSet { persistIfNeeded() } }
    @Published var showBottomLyrics = true { didSet { persistIfNeeded() } }
    @Published var lineMode: LyricsLineMode = .single { didSet { persistIfNeeded() } }
    @Published var showTranslation = true { didSet { persistIfNeeded() } }
    @Published var widthMode: OverlayWidthMode = .adaptive { didSet { persistIfNeeded() } }
    @Published var lyricsAlignment: LyricsTextAlignmentOption = .center { didSet { persistIfNeeded() } }
    @Published var useArtworkColors = true { didSet { persistIfNeeded() } }
    @Published var enableTrackAnimation = true { didSet { persistIfNeeded() } }
    @Published var hideInFullScreen = false { didSet { persistIfNeeded() } }
    @Published var reduceMotion = false { didSet { persistIfNeeded() } }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
        isBootstrapping = false
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
        expandOnHover = persisted.expandOnHover
        showBottomLyrics = persisted.showBottomLyrics
        lineMode = persisted.lineMode
        showTranslation = persisted.showTranslation
        widthMode = persisted.widthMode
        lyricsAlignment = persisted.lyricsAlignment
        useArtworkColors = persisted.useArtworkColors
        enableTrackAnimation = persisted.enableTrackAnimation
        hideInFullScreen = persisted.hideInFullScreen
        reduceMotion = persisted.reduceMotion
    }

    private func persistIfNeeded() {
        guard !isBootstrapping else { return }

        let persisted = PersistedSettings(
            showIsland: showIsland,
            expandOnHover: expandOnHover,
            showBottomLyrics: showBottomLyrics,
            lineMode: lineMode,
            showTranslation: showTranslation,
            widthMode: widthMode,
            lyricsAlignment: lyricsAlignment,
            useArtworkColors: useArtworkColors,
            enableTrackAnimation: enableTrackAnimation,
            hideInFullScreen: hideInFullScreen,
            reduceMotion: reduceMotion
        )

        guard let data = try? JSONEncoder().encode(persisted) else { return }
        userDefaults.set(data, forKey: Storage.key)
    }
}
