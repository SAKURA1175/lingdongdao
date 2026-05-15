import Foundation
import Testing
@testable import lingdongdao

@Suite("lingdongdao")
struct LingdongdaoTests {
    @Test @MainActor
    func appliesCurrentAndUpcomingLyricLine() async throws {
        let settings = UserDefaults(suiteName: UUID().uuidString)!
        let store = OverlaySettingsStore(userDefaults: settings)
        let state = LyricsOverlayState(settings: store)
        let lyrics = [
            TimedLyricLine(startTime: 0, endTime: 4, text: "line1", translation: "t1"),
            TimedLyricLine(startTime: 4, endTime: 8, text: "line2", translation: "t2"),
            TimedLyricLine(startTime: 8, endTime: 12, text: "line3", translation: "t3")
        ]

        state.apply(
            snapshot: NowPlayingSnapshot(
                track: .placeholder,
                lyrics: lyrics,
                progress: 5,
                isPlaying: true
            )
        )

        #expect(state.activeLine?.text == "line2")
        #expect(state.upcomingLine?.text == "line3")
    }

    @Test @MainActor
    func presentationStateExpandsAndCollapsesAfterHover() async throws {
        let settings = OverlaySettingsStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        let presentation = OverlayPresentationState()

        presentation.updateHover(isInside: true, settings: settings)
        #expect(presentation.isExpanded == true)

        presentation.updateHover(isInside: false, settings: settings)
        try await Task.sleep(nanoseconds: 220_000_000)

        #expect(presentation.isExpanded == false)
        #expect(presentation.phase == .collapsed)
    }

    @Test @MainActor
    func settingsPersistAcrossInstances() async throws {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!

        let first = OverlaySettingsStore(userDefaults: defaults)
        first.showTranslation = false
        first.widthMode = .maxWidth
        first.lineMode = .double

        let second = OverlaySettingsStore(userDefaults: defaults)
        #expect(second.showTranslation == false)
        #expect(second.widthMode == .maxWidth)
        #expect(second.lineMode == .double)
    }

    @Test @MainActor
    func adaptiveWidthStaysFixedAndMaxWidthCaps() async throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let settings = OverlaySettingsStore(userDefaults: defaults)
        let engine = LyricsLayoutEngine()

        let shortLine = TimedLyricLine(startTime: 0, text: "short")
        let longLine = TimedLyricLine(startTime: 0, text: "this is a much longer lyric line for width testing")

        settings.widthMode = .adaptive

        let adaptiveShort = engine.makeLayout(
            track: .placeholder,
            currentLine: shortLine,
            nextLine: shortLine,
            settings: settings,
            isExpanded: false
        )

        let adaptiveLong = engine.makeLayout(
            track: .placeholder,
            currentLine: longLine,
            nextLine: longLine,
            settings: settings,
            isExpanded: false
        )

        settings.widthMode = .maxWidth
        let maxWidthLayout = engine.makeLayout(
            track: .placeholder,
            currentLine: longLine,
            nextLine: longLine,
            settings: settings,
            isExpanded: false
        )

        #expect(adaptiveLong.collapsedWidth == adaptiveShort.collapsedWidth)
        #expect(maxWidthLayout.collapsedWidth == 430)
    }
}
