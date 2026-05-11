import SwiftUI

enum AnimationTokens {
    static let expandCollapse = Animation.spring(response: 0.42, dampingFraction: 0.86, blendDuration: 0.08)
    static let lyricSwap = Animation.easeOut(duration: 0.28)
    static let trackChange = Animation.easeInOut(duration: 0.36)
    static let widthChange = Animation.easeInOut(duration: 0.30)
    static let translationToggle = Animation.easeOut(duration: 0.22)
    static let fadeReveal = Animation.easeOut(duration: 0.20)
    static let reduced = Animation.easeOut(duration: 0.14)
    static let phaseSettle = Animation.easeOut(duration: 0.18)

    static func motion(reduceMotion: Bool) -> Animation {
        reduceMotion ? reduced : expandCollapse
    }
}
