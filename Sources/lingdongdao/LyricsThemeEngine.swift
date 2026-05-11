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

struct LyricsThemeEngine {
    func makeTheme(for track: NowPlayingTrack, settings: OverlaySettingsStore) -> IslandTheme {
        let accent = settings.useArtworkColors ? (Color(hex: track.accentColorHex) ?? .pink) : Color.white.opacity(0.96)
        let secondary = settings.useArtworkColors ? (Color(hex: track.secondaryColorHex) ?? .orange) : Color.white.opacity(0.5)

        return IslandTheme(
            accentColor: accent,
            secondaryAccent: secondary,
            backgroundColor: Color(red: 0.045, green: 0.05, blue: 0.065),
            elevatedBackground: Color(red: 0.075, green: 0.08, blue: 0.105),
            primaryText: Color.white.opacity(0.98),
            secondaryText: Color.white.opacity(0.68),
            tertiaryText: Color.white.opacity(0.38),
            borderColor: Color.white.opacity(0.10),
            glowColor: accent.opacity(settings.useArtworkColors ? 0.26 : 0.12)
        )
    }
}
