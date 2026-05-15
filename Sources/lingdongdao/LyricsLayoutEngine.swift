import CoreGraphics
import SwiftUI

struct OverlayLayout: Equatable {
    let collapsedWidth: CGFloat
    let collapsedHeight: CGFloat
    let collapsedLyricsHeight: CGFloat
    let reservesSecondaryLine: Bool
    let textAlignment: TextAlignment
    let horizontalAlignment: HorizontalAlignment
}

@MainActor
struct LyricsLayoutEngine {
    private enum Metrics {
        static let capsuleHeight: CGFloat = 42
        static let lyricsSpacing: CGFloat = 14
        static let singleLyricsHeight: CGFloat = 22
        static let doubleLyricsHeight: CGFloat = 40
    }

    func makeLayout(
        track: NowPlayingTrack,
        currentLine: TimedLyricLine?,
        nextLine: TimedLyricLine?,
        settings: OverlaySettingsStore
    ) -> OverlayLayout {
        let isSplit = settings.islandStyle == .split
        let width = isSplit ? 310 : capsuleWidth(settings: settings)
        let reservesSecondaryLine = settings.showBottomLyrics && (settings.lineMode == .double || settings.showTranslation)
        let lyricsHeight = settings.showBottomLyrics
            ? (reservesSecondaryLine ? Metrics.doubleLyricsHeight : Metrics.singleLyricsHeight)
            : 0

        let baseCapsuleHeight = Metrics.capsuleHeight

        let totalHeight = baseCapsuleHeight
            + (settings.showBottomLyrics ? Metrics.lyricsSpacing + lyricsHeight : 0)

        return OverlayLayout(
            collapsedWidth: width,
            collapsedHeight: totalHeight,
            collapsedLyricsHeight: lyricsHeight,
            reservesSecondaryLine: reservesSecondaryLine,
            textAlignment: settings.lyricsAlignment.textAlignment,
            horizontalAlignment: settings.lyricsAlignment.horizontalAlignment
        )
    }

    private func capsuleWidth(settings: OverlaySettingsStore) -> CGFloat {
        switch settings.widthMode {
        case .default:
            return 286
        case .adaptive:
            return settings.showBottomLyrics ? 338 : 320
        case .maxWidth:
            return 430
        }
    }
}
