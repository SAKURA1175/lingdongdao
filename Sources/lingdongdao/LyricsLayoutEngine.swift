import CoreGraphics
import SwiftUI

struct OverlayLayout: Equatable {
    let collapsedWidth: CGFloat
    let collapsedHeight: CGFloat
    let expandedSize: CGSize
    let textAlignment: TextAlignment
    let horizontalAlignment: HorizontalAlignment
}

struct LyricsLayoutEngine {
    func makeLayout(
        track: NowPlayingTrack,
        currentLine: TimedLyricLine?,
        nextLine: TimedLyricLine?,
        settings: OverlaySettingsStore,
        isExpanded: Bool
    ) -> OverlayLayout {
        let referenceText = currentLine?.text ?? track.title
        let nextText = nextLine?.text ?? track.artist
        let width = collapsedWidth(
            referenceText: referenceText,
            secondaryText: nextText,
            settings: settings
        )

        let collapsedHeight: CGFloat
        if settings.showBottomLyrics {
            collapsedHeight = settings.lineMode == .double || settings.showTranslation ? 94 : 76
        } else {
            collapsedHeight = 50
        }

        let expandedWidth: CGFloat = settings.showTranslation ? 784 : 748
        let expandedHeight: CGFloat = settings.lineMode == .double ? 262 : 236

        return OverlayLayout(
            collapsedWidth: width,
            collapsedHeight: collapsedHeight,
            expandedSize: CGSize(width: expandedWidth, height: expandedHeight),
            textAlignment: settings.lyricsAlignment.textAlignment,
            horizontalAlignment: settings.lyricsAlignment.horizontalAlignment
        )
    }

    private func collapsedWidth(
        referenceText: String,
        secondaryText: String,
        settings: OverlaySettingsStore
    ) -> CGFloat {
        switch settings.widthMode {
        case .default:
            return 286
        case .adaptive:
            let combined = max(referenceText.count, secondaryText.count)
            let estimate = CGFloat(combined) * 7.5 + 106
            let adjusted = settings.lineMode == .double ? estimate + 26 : estimate
            return min(max(272, adjusted), 420)
        case .maxWidth:
            return 430
        }
    }
}
