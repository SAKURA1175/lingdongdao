import SwiftUI

private enum OverlayAnimationTokens {
    static let spring = Animation.spring(response: 0.44, dampingFraction: 0.88, blendDuration: 0.10)
    static let lyricSwap = Animation.easeOut(duration: 0.26)
    static let widthChange = Animation.easeInOut(duration: 0.28)
    static let reduced = Animation.easeOut(duration: 0.16)
}

struct LyricsOverlayRootView: View {
    @ObservedObject var state: LyricsOverlayState

    private var theme: IslandTheme { state.theme }
    private var layout: OverlayLayout { state.layout }
    private var motionAnimation: Animation { state.settings.reduceMotion ? OverlayAnimationTokens.reduced : OverlayAnimationTokens.spring }

    var body: some View {
        ZStack(alignment: .top) {
            if state.isExpanded {
                ExpandedIslandView(state: state, theme: theme, layout: layout)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.985, anchor: .top)),
                        removal: .opacity
                    ))
            } else {
                CollapsedIslandView(state: state, theme: theme, layout: layout)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: -4)),
                        removal: .opacity
                    ))
            }
        }
        .frame(
            width: state.isExpanded ? layout.expandedSize.width : layout.collapsedWidth,
            height: state.isExpanded ? layout.expandedSize.height : layout.collapsedHeight,
            alignment: .top
        )
        .animation(motionAnimation, value: state.isExpanded)
        .animation(OverlayAnimationTokens.widthChange, value: layout.collapsedWidth)
        .preferredColorScheme(.dark)
    }
}

private struct CollapsedIslandView: View {
    @ObservedObject var state: LyricsOverlayState
    let theme: IslandTheme
    let layout: OverlayLayout

    @State private var visualizerPhase = false

    var body: some View {
        VStack(spacing: state.settings.showBottomLyrics ? 8 : 0) {
            HStack(spacing: 10) {
                AlbumBadge(symbol: state.nowPlaying.artworkSymbol, theme: theme)
                    .frame(width: 24, height: 24)

                if !state.settings.showBottomLyrics {
                    lyricHeadline
                } else {
                    trackHeader
                }

                Spacer(minLength: 6)

                MiniVisualizer(theme: theme, isAnimating: visualizerPhase, reduceMotion: state.settings.reduceMotion)
                    .onAppear { visualizerPhase = true }
            }
            .padding(.horizontal, 11)
            .frame(width: layout.collapsedWidth, height: 42)
            .background {
                ZStack {
                    Capsule(style: .continuous)
                        .fill(Color.black.opacity(0.98))

                    Capsule(style: .continuous)
                        .strokeBorder(theme.borderColor, lineWidth: 0.6)

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [theme.glowColor.opacity(0.6), .clear, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .blur(radius: 14)
                }
            }

            if state.settings.showBottomLyrics {
                bottomLyrics
                    .frame(width: layout.collapsedWidth - 22, alignment: alignmentFrame)
                    .transition(.opacity.combined(with: .offset(y: 5)))
            }
        }
    }

    private var alignmentFrame: Alignment {
        switch state.settings.lyricsAlignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }

    private var lyricHeadline: some View {
        Text(state.activeLine?.text ?? state.nowPlaying.title)
            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
            .foregroundStyle(theme.primaryText)
            .lineLimit(1)
            .multilineTextAlignment(layout.textAlignment)
            .id("collapsed-main-\(state.presentation.lyricTransitionToken)-\(state.activeLine?.id.uuidString ?? "none")")
            .contentTransition(.opacity)
            .animation(OverlayAnimationTokens.lyricSwap, value: state.presentation.lyricTransitionToken)
    }

    private var trackHeader: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(state.nowPlaying.artist)
                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                .foregroundStyle(theme.secondaryText)
                .lineLimit(1)

            Text(state.nowPlaying.title)
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.primaryText.opacity(0.88))
                .lineLimit(1)
        }
    }

    private var bottomLyrics: some View {
        VStack(alignment: layout.horizontalAlignment, spacing: 3) {
            Text(state.activeLine?.text ?? state.nowPlaying.title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(theme.primaryText)
                .lineLimit(1)
                .multilineTextAlignment(layout.textAlignment)
                .id("collapsed-bottom-\(state.presentation.lyricTransitionToken)-\(state.activeLine?.id.uuidString ?? "none")")

            if let secondaryText {
                Text(secondaryText)
                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(1)
                    .multilineTextAlignment(layout.textAlignment)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignmentFrame)
        .animation(OverlayAnimationTokens.lyricSwap, value: state.presentation.lyricTransitionToken)
    }

    private var secondaryText: String? {
        if state.settings.showTranslation, let translation = state.activeLine?.translation, !translation.isEmpty {
            return translation
        }

        guard state.settings.lineMode == .double else { return nil }
        return state.upcomingLine?.text
    }
}

private struct ExpandedIslandView: View {
    @ObservedObject var state: LyricsOverlayState
    let theme: IslandTheme
    let layout: OverlayLayout

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(theme.backgroundColor)
                .overlay {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [theme.glowColor.opacity(0.55), .clear, .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blur(radius: 36)
                        .mask(RoundedRectangle(cornerRadius: 34, style: .continuous))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .strokeBorder(theme.borderColor, lineWidth: 0.8)
                }

            VStack(spacing: 0) {
                Capsule()
                    .fill(theme.primaryText.opacity(0.12))
                    .frame(width: 66, height: 6)
                    .padding(.top, 12)

                HStack(alignment: .top, spacing: 28) {
                    playerColumn
                        .frame(width: 228)

                    lyricColumn
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 22)
            }
        }
        .frame(width: layout.expandedSize.width, height: layout.expandedSize.height)
    }

    private var playerColumn: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [theme.accentColor.opacity(0.85), theme.secondaryAccent.opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(alignment: .topLeading) {
                        Text(state.nowPlaying.album.uppercased())
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(theme.primaryText.opacity(0.24))
                            .padding(14)
                    }
                    .shadow(color: theme.glowColor, radius: 18, y: 10)

                Circle()
                    .fill(Color.black.opacity(0.68))
                    .frame(width: 34, height: 34)
                    .overlay {
                        Image(systemName: state.nowPlaying.artworkSymbol)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(theme.primaryText)
                    }
                    .overlay(Circle().strokeBorder(theme.borderColor, lineWidth: 0.6))
                    .offset(x: -10, y: -10)
            }
            .frame(width: 150, height: 150)
            .id("track-art-\(state.presentation.trackTransitionToken)-\(state.nowPlaying.id)")

            VStack(alignment: .leading, spacing: 5) {
                Text(state.nowPlaying.title)
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.primaryText)
                    .lineLimit(2)

                Text(state.nowPlaying.artist)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(1)
            }

            progressBlock
            controlsRow
        }
    }

    private var progressBlock: some View {
        VStack(spacing: 8) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(theme.primaryText.opacity(0.12))
                    Capsule()
                        .fill(theme.primaryText.opacity(0.95))
                        .frame(width: proxy.size.width * progressFraction)
                }
            }
            .frame(height: 5)

            HStack {
                Text(formattedTime(state.progress))
                Spacer()
                Text(formattedTime(state.nowPlaying.duration))
            }
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundStyle(theme.tertiaryText)
        }
    }

    private var controlsRow: some View {
        HStack(spacing: 18) {
            CircleControl(symbol: "backward.fill", theme: theme)
            CircleControl(symbol: state.isPlaying ? "pause.fill" : "play.fill", theme: theme, prominent: true)
            CircleControl(symbol: "forward.fill", theme: theme)
        }
    }

    private var lyricColumn: some View {
        VStack(alignment: layout.horizontalAlignment, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NOW PLAYING")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(theme.tertiaryText)
                    Text(state.phaseTitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.secondaryText)
                }
                Spacer()
            }

            Spacer(minLength: 0)

            if let previous = state.previousLine?.text {
                Text(previous)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.tertiaryText)
                    .multilineTextAlignment(layout.textAlignment)
                    .frame(maxWidth: .infinity, alignment: frameAlignment)
                    .blur(radius: state.settings.reduceMotion ? 0 : 0.4)
            }

            VStack(alignment: layout.horizontalAlignment, spacing: 8) {
                Text(state.activeLine?.text ?? state.nowPlaying.title)
                    .font(.system(size: 31, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.primaryText)
                    .multilineTextAlignment(layout.textAlignment)
                    .frame(maxWidth: .infinity, alignment: frameAlignment)
                    .id("expanded-main-\(state.presentation.lyricTransitionToken)-\(state.activeLine?.id.uuidString ?? "none")")

                if state.settings.showTranslation, let translation = state.activeLine?.translation, !translation.isEmpty {
                    Text(translation)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.secondaryText)
                        .multilineTextAlignment(layout.textAlignment)
                        .frame(maxWidth: .infinity, alignment: frameAlignment)
                }
            }
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.elevatedBackground.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(theme.borderColor.opacity(0.8), lineWidth: 0.6)
                    )
            )
            .shadow(color: theme.glowColor.opacity(0.28), radius: 18, y: 8)

            if let next = state.upcomingLine?.text {
                Text(next)
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.secondaryText)
                    .multilineTextAlignment(layout.textAlignment)
                    .frame(maxWidth: .infinity, alignment: frameAlignment)
            }

            Spacer(minLength: 0)

            if state.settings.lineMode == .double, let next = state.upcomingLine?.translation, state.settings.showTranslation {
                Text(next)
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.tertiaryText)
                    .frame(maxWidth: .infinity, alignment: frameAlignment)
            }
        }
        .animation(OverlayAnimationTokens.lyricSwap, value: state.presentation.lyricTransitionToken)
    }

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

private extension LyricsOverlayState {
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

private struct AlbumBadge: View {
    let symbol: String
    let theme: IslandTheme

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [theme.accentColor.opacity(0.95), theme.secondaryAccent.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white.opacity(0.85))
            }
    }
}

private struct MiniVisualizer: View {
    let theme: IslandTheme
    let isAnimating: Bool
    let reduceMotion: Bool

    var body: some View {
        HStack(spacing: 2.5) {
            ForEach(Array([8.0, 14.0, 10.0, 6.0].enumerated()), id: \.offset) { index, base in
                Capsule()
                    .fill(theme.accentColor.opacity(0.92))
                    .frame(width: 3, height: reduceMotion ? 6 : (isAnimating ? base : 4))
                    .animation(
                        reduceMotion
                            ? .none
                            : .easeInOut(duration: 0.42 + Double(index) * 0.04)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.08),
                        value: isAnimating
                    )
            }
        }
        .frame(width: 24, height: 16)
    }
}

private struct CircleControl: View {
    let symbol: String
    let theme: IslandTheme
    var prominent = false

    var body: some View {
        Circle()
            .fill(prominent ? theme.primaryText : theme.primaryText.opacity(0.10))
            .frame(width: prominent ? 40 : 34, height: prominent ? 40 : 34)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: prominent ? 15 : 13, weight: .bold))
                    .foregroundStyle(prominent ? theme.backgroundColor : theme.primaryText)
            }
            .overlay {
                Circle()
                    .strokeBorder(prominent ? Color.clear : theme.borderColor, lineWidth: 0.6)
            }
    }
}
