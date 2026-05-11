import Foundation
import SwiftUI

struct TimedLyricLine: Identifiable, Codable, Equatable {
    let id: UUID
    let startTime: TimeInterval
    let endTime: TimeInterval?
    let text: String
    let translation: String?

    init(
        id: UUID = UUID(),
        startTime: TimeInterval,
        endTime: TimeInterval? = nil,
        text: String,
        translation: String? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
        self.translation = translation
    }
}

struct NowPlayingTrack: Equatable, Identifiable, Codable {
    let id: String
    let title: String
    let artist: String
    let album: String
    let accentColorHex: String
    let secondaryColorHex: String
    let duration: TimeInterval
    let artworkSymbol: String

    static let placeholder = NowPlayingTrack(
        id: "placeholder.track",
        title: "BLiNK",
        artist: "MONKEY MAJIK × UQiYO",
        album: "COLLABO RATED",
        accentColorHex: "#D81B60",
        secondaryColorHex: "#FF7AA8",
        duration: 277,
        artworkSymbol: "music.note"
    )
}

struct NowPlayingSnapshot: Equatable {
    let track: NowPlayingTrack
    let lyrics: [TimedLyricLine]
    let progress: TimeInterval
    let isPlaying: Bool
}

enum OverlayWidthMode: String, Codable, CaseIterable, Identifiable {
    case `default`
    case adaptive
    case maxWidth

    var id: String { rawValue }

    var label: String {
        switch self {
        case .default: return "默认"
        case .adaptive: return "自适应"
        case .maxWidth: return "最长"
        }
    }
}

enum LyricsLineMode: String, Codable, CaseIterable, Identifiable {
    case single
    case double

    var id: String { rawValue }

    var label: String {
        switch self {
        case .single: return "单行"
        case .double: return "双行"
        }
    }
}

enum LyricsTextAlignmentOption: String, Codable, CaseIterable, Identifiable {
    case leading
    case center
    case trailing

    var id: String { rawValue }

    var label: String {
        switch self {
        case .leading: return "左对齐"
        case .center: return "居中"
        case .trailing: return "右对齐"
        }
    }

    var textAlignment: TextAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }

    var horizontalAlignment: HorizontalAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

extension Color {
    init?(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard sanitized.count == 6, let value = Int(sanitized, radix: 16) else {
            return nil
        }

        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
