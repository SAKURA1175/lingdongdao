import SwiftUI

private enum OverlayAnimationTokens {
    static let lyricSwap = Animation.easeOut(duration: 0.26)
    static let widthChange = Animation.easeInOut(duration: 0.28)
    static let reduced = Animation.easeOut(duration: 0.16)
}

private enum CapsuleMetrics {
    static let horizontalPadding: CGFloat = 11
    static let bottomSpacing: CGFloat = 14
    static let leadingSpacing: CGFloat = 10
    static let trailingGroupWidth: CGFloat = 28
    static let panelHorizontalInset: CGFloat = 10
}

struct LyricsOverlayRootView: View {
    @ObservedObject var state: LyricsOverlayState

    private var theme: IslandTheme { state.theme }
    private var layout: OverlayLayout { state.layout }

    var body: some View {
        VStack(spacing: 0) {
            capsule

            if state.settings.showBottomLyrics {
                bottomLyrics
                    .frame(
                        width: layout.collapsedWidth - (CapsuleMetrics.panelHorizontalInset * 2),
                        alignment: alignmentFrame
                    )
                    .padding(.top, CapsuleMetrics.bottomSpacing)
                    .transition(.opacity.combined(with: .offset(y: 5)))
            }
        }
        .frame(width: layout.collapsedWidth, height: layout.collapsedHeight, alignment: .top)
        .animation(OverlayAnimationTokens.widthChange, value: layout.collapsedWidth)
        .preferredColorScheme(.dark)
    }

    // MARK: - Capsule (the pill bar)

    private var capsule: some View {
        let isSplit = state.settings.islandStyle == .split

        return HStack(spacing: 0) {
            HStack(spacing: CapsuleMetrics.leadingSpacing) {
                AlbumBadge(symbol: state.nowPlaying.artworkSymbol, theme: theme)
                    .frame(width: 24, height: 24)

                if !isSplit {
                    capsuleLeadingContent
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Spacer(minLength: 0)

            MiniVisualizer(theme: theme, isAnimating: true, reduceMotion: state.settings.reduceMotion)
                .frame(width: CapsuleMetrics.trailingGroupWidth, alignment: .trailing)
        }
        .padding(.horizontal, CapsuleMetrics.horizontalPadding)
        .frame(width: layout.collapsedWidth, height: 42)
        .background {
            IslandCapsuleSurface(theme: theme, cornerRadius: 22)
        }
    }

    @ViewBuilder
    private var capsuleLeadingContent: some View {
        if !state.settings.showBottomLyrics {
            lyricHeadline
        } else {
            trackHeader
        }
    }

    // MARK: - Lyrics below capsule

    private var lyricHeadline: some View {
        KaraokeTextView(
            text: state.activeLine?.text ?? state.nowPlaying.title,
            progress: lineProgress,
            baseColor: state.settings.karaokeMode ? theme.secondaryText : theme.primaryText,
            fillColor: theme.accentColor,
            font: .system(size: 13.5, weight: .semibold, design: .rounded),
            alignment: layout.textAlignment,
            fillAlignment: state.settings.karaokeFillDirection == .leading ? .leading : .center
        )
        .id("main-\(state.presentation.lyricTransitionToken)-\(state.activeLine?.id.uuidString ?? "none")")
        .contentTransition(.opacity)
        .animation(OverlayAnimationTokens.lyricSwap, value: state.presentation.lyricTransitionToken)
    }

    private var trackHeader: some View {
        VStack(alignment: .leading, spacing: -1) {
            Text(state.nowPlaying.artist)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(theme.secondaryText)
                .lineLimit(1)
                .truncationMode(.tail)

            Text("正在播放")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(theme.primaryText.opacity(0.88))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var bottomLyrics: some View {
        VStack(alignment: layout.horizontalAlignment, spacing: 3) {
            KaraokeTextView(
                text: state.activeLine?.text ?? state.nowPlaying.title,
                progress: lineProgress,
                baseColor: state.settings.karaokeMode ? theme.secondaryText : theme.primaryText,
                fillColor: theme.accentColor,
                font: .system(size: 15, weight: .bold, design: .rounded),
                alignment: layout.textAlignment,
                fillAlignment: state.settings.karaokeFillDirection == .leading ? .leading : .center
            )
                .id("bottom-\(state.presentation.lyricTransitionToken)-\(state.activeLine?.id.uuidString ?? "none")")
                .shadow(color: .black.opacity(0.35), radius: 5, y: 1)

            if layout.reservesSecondaryLine {
                Text(secondaryText ?? " ")
                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .multilineTextAlignment(layout.textAlignment)
                    .opacity(secondaryText == nil ? 0 : 1)
                    .shadow(color: .black.opacity(0.28), radius: 4, y: 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignmentFrame)
        .animation(OverlayAnimationTokens.lyricSwap, value: state.presentation.lyricTransitionToken)
    }

    private var alignmentFrame: Alignment {
        switch state.settings.lyricsAlignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }

    private var secondaryText: String? {
        if state.settings.showTranslation, let translation = state.activeLine?.translation, !translation.isEmpty {
            return translation
        }
        guard state.settings.lineMode == .double else { return nil }
        return state.upcomingLine?.text
    }

    private var lineProgress: Double {
        guard state.settings.karaokeMode, let line = state.activeLine else { return 0 }
        let start = line.startTime
        let end = line.endTime ?? state.upcomingLine?.startTime ?? (start + 5.0)
        let duration = max(0.1, end - start)
        let progress = (state.progress - start) / duration
        return min(max(progress, 0), 1)
    }
}

private struct KaraokeTextView: View {
    let text: String
    let progress: Double
    let baseColor: Color
    let fillColor: Color
    let font: Font
    let alignment: TextAlignment
    let fillAlignment: Alignment

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(baseColor)
            .lineLimit(1)
            .truncationMode(.tail)
            .multilineTextAlignment(alignment)
            .overlay(
                GeometryReader { geo in
                    Text(text)
                        .font(font)
                        .foregroundStyle(fillColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .multilineTextAlignment(alignment)
                        .frame(width: geo.size.width, alignment: alignment == .leading ? .leading : (alignment == .trailing ? .trailing : .center))
                        .mask(
                            Rectangle()
                                .frame(width: geo.size.width * CGFloat(progress))
                                .frame(maxWidth: .infinity, alignment: fillAlignment)
                        )
                }
            )
            .animation(.linear(duration: 0.5), value: progress)
    }
}

private struct IslandCapsuleSurface: View {
    let theme: IslandTheme
    var cornerRadius: CGFloat = 22

    private var shell: some InsettableShape {
        UnevenRoundedRectangle(
            cornerRadii: .init(
                topLeading: cornerRadius,
                bottomLeading: cornerRadius,
                bottomTrailing: cornerRadius,
                topTrailing: cornerRadius
            ),
            style: .continuous
        )
    }

    var body: some View {
        ZStack {
            shell
                .fill(Color.black.opacity(0.98))

            shell
                .fill(
                    LinearGradient(
                        colors: [theme.glowColor.opacity(0.6), .clear, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .blur(radius: 14)
        }
        .compositingGroup()
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
