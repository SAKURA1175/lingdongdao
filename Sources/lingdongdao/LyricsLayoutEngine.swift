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
            collapsedHeight = settings.lineMode == .double || settings.showTranslation ? 90 : 72
        } else {
            collapsedHeight = 46
        }

        let expandedWidth: CGFloat
        switch settings.widthMode {
        case .default:
            expandedWidth = settings.showTranslation ? 520 : 480
        case .adaptive:
            let charWidth = CGFloat(max(referenceText.count, nextText.count)) * 8.0 + 140
            expandedWidth = min(max(420, charWidth), 620)
        case .maxWidth:
            expandedWidth = 640
        }

        let expandedHeight: CGFloat
        if settings.showTranslation && settings.lineMode == .double {
            expandedHeight = 280
        } else if settings.showTranslation || settings.lineMode == .double {
            expandedHeight = 256
        } else {
            expandedHeight = 232
        }

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
