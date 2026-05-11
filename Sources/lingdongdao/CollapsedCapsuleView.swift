import SwiftUI

struct CollapsedCapsuleView: View {
    @ObservedObject var state: LyricsOverlayState
    let theme: IslandTheme
    let layout: OverlayLayout

    @State private var visualizerPhase = false

    var body: some View {
        VStack(spacing: state.settings.showBottomLyrics ? 6 : 0) {
            capsuleBar
            if state.settings.showBottomLyrics {
                bottomLyricsBlock
                    .transition(.opacity.combined(with: .offset(y: 4)))
                    .animation(AnimationTokens.fadeReveal, value: state.settings.showBottomLyrics)
            }
        }
    }

    // MARK: - Capsule bar

    private var capsuleBar: some View {
        HStack(spacing: 8) {
            AlbumBadge(symbol: state.nowPlaying.artworkSymbol, theme: theme, size: 22)

            inlineLyric
                .frame(maxWidth: .infinity, alignment: capsuleAlignment)

            MiniVisualizer(
                theme: theme,
                isAnimating: visualizerPhase,
                reduceMotion: state.settings.reduceMotion
            )
            .onAppear { visualizerPhase = true }
        }
        .padding(.horizontal, 12)
        .frame(width: layout.collapsedWidth, height: 40)
        .background { capsuleBackground }
    }

    private var inlineLyric: some View {
        Group {
            if state.settings.showBottomLyrics {
                compactTrackInfo
            } else {
                lyricTextLine
            }
        }
    }

    private var lyricTextLine: some View {
        Text(state.activeLine?.text ?? state.nowPlaying.title)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(theme.primaryText)
            .lineLimit(1)
            .multilineTextAlignment(layout.textAlignment)
            .mask(trailingFadeMask)
            .id("capsule-inline-\(state.presentation.lyricTransitionToken)-\(state.activeLine?.id.uuidString ?? "none")")
            .contentTransition(.opacity)
            .animation(AnimationTokens.lyricSwap, value: state.presentation.lyricTransitionToken)
    }

    private var compactTrackInfo: some View {
        Text(state.nowPlaying.title)
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(theme.secondaryText)
            .lineLimit(1)
    }

    // MARK: - Bottom lyrics

    private var bottomLyricsBlock: some View {
        VStack(alignment: layout.horizontalAlignment, spacing: 3) {
            currentLyricLine
            secondaryLyricLine
        }
        .frame(width: layout.collapsedWidth - 24, alignment: capsuleFrameAlignment)
        .animation(AnimationTokens.lyricSwap, value: state.presentation.lyricTransitionToken)
    }

    private var currentLyricLine: some View {
        Text(state.activeLine?.text ?? state.nowPlaying.title)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(theme.primaryText)
            .lineLimit(1)
            .multilineTextAlignment(layout.textAlignment)
            .mask(trailingFadeMask)
            .id("capsule-bottom-\(state.presentation.lyricTransitionToken)-\(state.activeLine?.id.uuidString ?? "none")")
            .contentTransition(.opacity)
    }

    @ViewBuilder
    private var secondaryLyricLine: some View {
        if let secondary = secondaryText {
            Text(secondary)
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .foregroundStyle(theme.secondaryText)
                .lineLimit(1)
                .multilineTextAlignment(layout.textAlignment)
                .mask(trailingFadeMask)
                .transition(.opacity.combined(with: .offset(y: 3)))
                .animation(AnimationTokens.translationToggle, value: state.settings.showTranslation)
        }
    }

    // MARK: - Helpers

    private var secondaryText: String? {
        if state.settings.showTranslation,
           let translation = state.activeLine?.translation,
           !translation.isEmpty {
            return translation
        }
        guard state.settings.lineMode == .double else { return nil }
        return state.upcomingLine?.text
    }

    private var capsuleFrameAlignment: Alignment {
        switch state.settings.lyricsAlignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }

    private var capsuleAlignment: Alignment {
        switch state.settings.lyricsAlignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }

    private var trailingFadeMask: some View {
        HStack(spacing: 0) {
            Color.white
            LinearGradient(
                colors: [.white, .white.opacity(0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 24)
        }
    }

    // MARK: - Background

    private var capsuleBackground: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.97))

            Capsule(style: .continuous)
                .strokeBorder(theme.borderColor, lineWidth: 0.5)

            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [theme.glowColor.opacity(0.48), .clear, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .blur(radius: 16)
        }
    }
}
