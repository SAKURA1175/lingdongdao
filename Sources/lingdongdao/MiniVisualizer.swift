import SwiftUI

struct MiniVisualizer: View {
    let theme: IslandTheme
    let isAnimating: Bool
    let reduceMotion: Bool

    private let bars: [CGFloat] = [7, 12, 9, 5]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(bars.enumerated()), id: \.offset) { index, base in
                Capsule()
                    .fill(theme.accentColor.opacity(0.72))
                    .frame(width: 2.5, height: reduceMotion ? 5 : (isAnimating ? base : 3.5))
                    .animation(
                        reduceMotion
                            ? .none
                            : .easeInOut(duration: 0.44 + Double(index) * 0.04)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.08),
                        value: isAnimating
                    )
            }
        }
        .frame(width: 20, height: 14)
        .opacity(0.7)
    }
}
