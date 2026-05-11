import SwiftUI

struct LyricsOverlayRootView: View {
    @ObservedObject var state: LyricsOverlayState

    private var theme: IslandTheme { state.theme }
    private var layout: OverlayLayout { state.layout }

    var body: some View {
        ZStack(alignment: .top) {
            if state.isExpanded {
                ExpandedImmersiveView(state: state, theme: theme, layout: layout)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.988, anchor: .top)),
                        removal: .opacity
                    ))
            } else {
                CollapsedCapsuleView(state: state, theme: theme, layout: layout)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: -3)),
                        removal: .opacity
                    ))
            }
        }
        .frame(
            width: state.isExpanded ? layout.expandedSize.width : layout.collapsedWidth,
            height: state.isExpanded ? layout.expandedSize.height : layout.collapsedHeight,
            alignment: .top
        )
        .animation(AnimationTokens.motion(reduceMotion: state.settings.reduceMotion), value: state.isExpanded)
        .animation(AnimationTokens.widthChange, value: layout.collapsedWidth)
        .animation(AnimationTokens.trackChange, value: state.presentation.trackTransitionToken)
        .preferredColorScheme(.dark)
    }
}
