import Foundation
import Testing
@testable import lingdongdao

@Test func appliesCurrentAndUpcomingLyricLine() async throws {
    let settings = UserDefaults(suiteName: UUID().uuidString)!
    let store = await OverlaySettingsStore(userDefaults: settings)
    let state = await LyricsOverlayState(settings: store)
    let lyrics = [
        TimedLyricLine(startTime: 0, endTime: 4, text: "line1", translation: "t1"),
        TimedLyricLine(startTime: 4, endTime: 8, text: "line2", translation: "t2"),
        TimedLyricLine(startTime: 8, endTime: 12, text: "line3", translation: "t3")
    ]

    await state.apply(
        snapshot: NowPlayingSnapshot(
            track: .placeholder,
            lyrics: lyrics,
            progress: 5,
            isPlaying: true
        )
    )

    let activeText = await state.activeLine?.text
    let upcomingText = await state.upcomingLine?.text

    #expect(activeText == "line2")
    #expect(upcomingText == "line3")
}

@Test func presentationStateExpandsAndCollapsesAfterHover() async throws {
    let settings = await OverlaySettingsStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
    let presentation = await OverlayPresentationState()

    await presentation.updateHover(isInside: true, settings: settings)
    #expect(await presentation.isExpanded == true)

    await presentation.updateHover(isInside: false, settings: settings)
    try await Task.sleep(nanoseconds: 220_000_000)

    #expect(await presentation.isExpanded == false)
    #expect(await presentation.phase == .collapsed)
}

@Test func settingsPersistAcrossInstances() async throws {
    let suiteName = UUID().uuidString
    let defaults = UserDefaults(suiteName: suiteName)!

    let first = await OverlaySettingsStore(userDefaults: defaults)
    await MainActor.run {
        first.showTranslation = false
        first.widthMode = .maxWidth
        first.lineMode = .double
    }

    let second = await OverlaySettingsStore(userDefaults: defaults)
    #expect(await second.showTranslation == false)
    #expect(await second.widthMode == .maxWidth)
    #expect(await second.lineMode == .double)
}

@Test func adaptiveWidthGrowsAndMaxWidthCaps() async throws {
    let defaults = UserDefaults(suiteName: UUID().uuidString)!
    let settings = await OverlaySettingsStore(userDefaults: defaults)
    let engine = LyricsLayoutEngine()

    let shortLine = TimedLyricLine(startTime: 0, text: "short")
    let longLine = TimedLyricLine(startTime: 0, text: "this is a much longer lyric line for width testing")

    let adaptiveShort = await MainActor.run {
        settings.widthMode = .adaptive
        return engine.makeLayout(
            track: .placeholder,
            currentLine: shortLine,
            nextLine: shortLine,
            settings: settings,
            isExpanded: false
        )
    }

    let adaptiveLong = await MainActor.run {
        engine.makeLayout(
            track: .placeholder,
            currentLine: longLine,
            nextLine: longLine,
            settings: settings,
            isExpanded: false
        )
    }

    let maxWidthLayout = await MainActor.run {
        settings.widthMode = .maxWidth
        return engine.makeLayout(
            track: .placeholder,
            currentLine: longLine,
            nextLine: longLine,
            settings: settings,
            isExpanded: false
        )
    }

    #expect(adaptiveLong.collapsedWidth > adaptiveShort.collapsedWidth)
    #expect(maxWidthLayout.collapsedWidth == 430)
}
