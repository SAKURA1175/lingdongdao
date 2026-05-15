import SwiftUI

struct IslandTheme: Equatable {
    let accentColor: Color
    let secondaryAccent: Color
    let backgroundColor: Color
    let elevatedBackground: Color
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let borderColor: Color
    let glowColor: Color
}

@MainActor
struct LyricsThemeEngine {
    func makeTheme(for track: NowPlayingTrack, settings: OverlaySettingsStore) -> IslandTheme {
        let accent = settings.useArtworkColors ? (Color(hex: track.accentColorHex) ?? .pink) : Color.white.opacity(0.96)
        let secondary = settings.useArtworkColors ? (Color(hex: track.secondaryColorHex) ?? .orange) : Color.white.opacity(0.5)
        let lyricPrimary = primaryTextColor(style: settings.lyricColorStyle, accent: accent)
        let lyricSecondary = secondaryTextColor(style: settings.lyricColorStyle, accent: accent, secondary: secondary)

        return IslandTheme(
            accentColor: accent,
            secondaryAccent: secondary,
            backgroundColor: Color(red: 0.045, green: 0.05, blue: 0.065),
            elevatedBackground: Color(red: 0.075, green: 0.08, blue: 0.105),
            primaryText: lyricPrimary,
            secondaryText: lyricSecondary,
            tertiaryText: Color.white.opacity(0.38),
            borderColor: Color.white.opacity(0.10),
            glowColor: accent.opacity(settings.useArtworkColors ? 0.26 : 0.12)
        )
    }

    private func primaryTextColor(style: LyricsColorStyle, accent: Color) -> Color {
        switch style {
        case .white:
            return Color.white.opacity(0.98)
        case .artwork:
            return accent.opacity(0.98)
        case .sky:
            return Color(red: 0.76, green: 0.90, blue: 1.0)
        case .gold:
            return Color(red: 1.0, green: 0.90, blue: 0.68)
        }
    }

    private func secondaryTextColor(style: LyricsColorStyle, accent: Color, secondary: Color) -> Color {
        switch style {
        case .white:
            return Color.white.opacity(0.68)
        case .artwork:
            return secondary.opacity(0.88)
        case .sky:
            return Color(red: 0.64, green: 0.82, blue: 0.96)
        case .gold:
            return Color(red: 0.92, green: 0.80, blue: 0.56)
        }
    }
}
