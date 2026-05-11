import SwiftUI

struct ExpandedImmersiveView: View {
    @ObservedObject var state: LyricsOverlayState
    let theme: IslandTheme
    let layout: OverlayLayout

    var body: some View {
        ZStack(alignment: .top) {
            panelBackground

            VStack(spacing: 0) {
                dragHandle
                    .padding(.top, 10)

                compactHeader
                    .padding(.horizontal, 28)
                    .padding(.top, 10)

                Spacer(minLength: 8)

                lyricsStack
                    .padding(.horizontal, 28)

                Spacer(minLength: 8)

                phaseIndicator
                    .padding(.bottom, 14)
            }
        }
        .frame(width: layout.expandedSize.width, height: layout.expandedSize.height)
    }

    // MARK: - Header (minimal)

    private var compactHeader: some View {
        HStack(spacing: 10) {
            AlbumBadge(symbol: state.nowPlaying.artworkSymbol, theme: theme, size: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(state.nowPlaying.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(1)

                Text(state.nowPlaying.artist)
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.tertiaryText)
                    .lineLimit(1)
            }

            Spacer()

            progressPill
        }
        .id("header-\(state.presentation.trackTransitionToken)-\(state.nowPlaying.id)")
        .animation(AnimationTokens.trackChange, value: state.presentation.trackTransitionToken)
    }

    private var progressPill: some View {
        let fraction = progressFraction
        return Text(formattedTime(state.progress))
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(theme.tertiaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(theme.elevatedBackground.opacity(0.6))
                    .overlay(alignment: .leading) {
                        GeometryReader { proxy in
                            Capsule()
                                .fill(theme.accentColor.opacity(0.18))
                                .frame(width: proxy.size.width * fraction)
                        }
                    }
                    .clipShape(Capsule())
            )
    }

    // MARK: - Lyrics stack (immersive)

    private var lyricsStack: some View {
        VStack(alignment: layout.horizontalAlignment, spacing: 10) {
            previousLyricLine
            currentLyricBlock
            upcomingLyricLine
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
        .animation(AnimationTokens.lyricSwap, value: state.presentation.lyricTransitionToken)
    }

    @ViewBuilder
    private var previousLyricLine: some View {
        if let previous = state.previousLine?.text {
            Text(previous)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(theme.tertiaryText)
                .multilineTextAlignment(layout.textAlignment)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: frameAlignment)
                .opacity(0.6)
        }
    }

    private var currentLyricBlock: some View {
        VStack(alignment: layout.horizontalAlignment, spacing: 6) {
            Text(state.activeLine?.text ?? state.nowPlaying.title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(theme.primaryText)
                .multilineTextAlignment(layout.textAlignment)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: frameAlignment)
                .id("expanded-main-\(state.presentation.lyricTransitionToken)-\(state.activeLine?.id.uuidString ?? "none")")
                .contentTransition(.opacity)

            if state.settings.showTranslation,
               let translation = state.activeLine?.translation,
               !translation.isEmpty {
                Text(translation)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.secondaryText)
                    .multilineTextAlignment(layout.textAlignment)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: frameAlignment)
                    .transition(.opacity.combined(with: .offset(y: 4)))
                    .animation(AnimationTokens.translationToggle, value: state.settings.showTranslation)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(theme.elevatedBackground.opacity(0.62))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(theme.borderColor.opacity(0.7), lineWidth: 0.5)
                )
        )
        .shadow(color: theme.glowColor.opacity(0.22), radius: 14, y: 6)
    }

    @ViewBuilder
    private var upcomingLyricLine: some View {
        if let next = state.upcomingLine?.text {
            VStack(alignment: layout.horizontalAlignment, spacing: 3) {
                Text(next)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.secondaryText)
                    .multilineTextAlignment(layout.textAlignment)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: frameAlignment)

                if state.settings.lineMode == .double,
                   state.settings.showTranslation,
                   let nextTranslation = state.upcomingLine?.translation,
                   !nextTranslation.isEmpty {
                    Text(nextTranslation)
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.tertiaryText)
                        .frame(maxWidth: .infinity, alignment: frameAlignment)
                }
            }
        }
    }

    // MARK: - Phase indicator

    private var phaseIndicator: some View {
        Text(state.phaseTitle)
            .font(.system(size: 9.5, weight: .medium, design: .rounded))
            .foregroundStyle(theme.tertiaryText.opacity(0.6))
            .animation(AnimationTokens.phaseSettle, value: state.phase)
    }

    // MARK: - Chrome

    private var dragHandle: some View {
        Capsule()
            .fill(theme.primaryText.opacity(0.10))
            .frame(width: 56, height: 5)
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(theme.backgroundColor)
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [theme.glowColor.opacity(0.45), .clear, .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 32)
                    .mask(RoundedRectangle(cornerRadius: 30, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .strokeBorder(theme.borderColor, lineWidth: 0.6)
            }
    }

    // MARK: - Helpers

    private var progressFraction: CGFloat {
        let duration = max(state.nowPlaying.duration, 1)
        return min(max(CGFloat(state.progress / duration), 0), 1)
    }

    private var frameAlignment: Alignment {
        switch state.settings.lyricsAlignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }

    private func formattedTime(_ time: TimeInterval) -> String {
        let total = max(Int(time.rounded(.down)), 0)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

extension LyricsOverlayState {
    var phaseTitle: String {
        switch phase {
        case .collapsed: return "收起待命"
        case .hoverExpanding: return "正在展开"
        case .expanded: return "歌词沉浸"
        case .hoverCollapsing: return "即将收起"
        case .trackTransition: return "切歌过渡"
        case .lyricTransition: return "歌词切换"
        }
    }
}
