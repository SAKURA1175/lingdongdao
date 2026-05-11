import SwiftUI

struct AlbumBadge: View {
    let symbol: String
    let theme: IslandTheme
    var size: CGFloat = 22

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        theme.accentColor.opacity(0.80),
                        theme.secondaryAccent.opacity(0.55),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.42, weight: .black))
                    .foregroundStyle(.white.opacity(0.78))
            }
            .frame(width: size, height: size)
    }
}
