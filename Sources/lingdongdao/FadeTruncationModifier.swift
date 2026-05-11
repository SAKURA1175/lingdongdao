import SwiftUI

struct FadeTruncation: ViewModifier {
    var maxWidth: CGFloat
    var fadeWidth: CGFloat = 28

    func body(content: Content) -> some View {
        content
            .fixedSize(horizontal: true, vertical: false)
            .frame(maxWidth: maxWidth, alignment: .leading)
            .clipped()
            .mask(
                HStack(spacing: 0) {
                    Color.white
                    LinearGradient(
                        colors: [.white, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: fadeWidth)
                }
            )
    }
}

extension View {
    func fadeTruncation(maxWidth: CGFloat, fadeWidth: CGFloat = 28) -> some View {
        modifier(FadeTruncation(maxWidth: maxWidth, fadeWidth: fadeWidth))
    }
}
