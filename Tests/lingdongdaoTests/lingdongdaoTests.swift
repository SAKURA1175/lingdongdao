import Foundation
import Testing
@testable import lingdongdao

// MARK: - Lyric line resolution

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

@Test func previousLineIsSetCorrectly() async throws {
    let store = await OverlaySettingsStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
    let state = await LyricsOverlayState(settings: store)
    let lyrics = [
        TimedLyricLine(startTime: 0, endTime: 4, text: "line1"),
        TimedLyricLine(startTime: 4, endTime: 8, text: "line2"),
        TimedLyricLine(startTime: 8, endTime: 12, text: "line3")
    ]

    await state.apply(
        snapshot: NowPlayingSnapshot(track: .placeholder, lyrics: lyrics, progress: 9, isPlaying: true)
    )

    #expect(await state.previousLine?.text == "line2")
    #expect(await state.activeLine?.text == "line3")
    #expect(await state.upcomingLine == nil)
}

@Test func firstLineHasNoPreviousLine() async throws {
    let store = await OverlaySettingsStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
    let state = await LyricsOverlayState(settings: store)
    let lyrics = [
        TimedLyricLine(startTime: 0, endTime: 4, text: "first"),
        TimedLyricLine(startTime: 4, endTime: 8, text: "second")
    ]

    await state.apply(
        snapshot: NowPlayingSnapshot(track: .placeholder, lyrics: lyrics, progress: 1, isPlaying: true)
    )

    #expect(await state.previousLine == nil)
    #expect(await state.activeLine?.text == "first")
    #expect(await state.upcomingLine?.text == "second")
}

// MARK: - Hover expand / collapse

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

@Test func hoverExpandDisabledWhenSettingOff() async throws {
    let store = await OverlaySettingsStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
    let presentation = await OverlayPresentationState()

    await MainActor.run { store.expandOnHover = false }

    await presentation.updateHover(isInside: true, settings: store)
    #expect(await presentation.isExpanded == false)
    #expect(await presentation.phase == .collapsed)
}

@Test func manualExpandCollapseWorksRegardlessOfHoverSetting() async throws {
    let store = await OverlaySettingsStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
    let presentation = await OverlayPresentationState()

    await MainActor.run { store.expandOnHover = false }

    await presentation.setExpanded(true)
    #expect(await presentation.isExpanded == true)

    await presentation.setExpanded(false)
    try await Task.sleep(nanoseconds: 300_000_000)
    #expect(await presentation.isExpanded == false)
}

// MARK: - Settings persistence

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

@Test func allSettingsRoundTrip() async throws {
    let defaults = UserDefaults(suiteName: UUID().uuidString)!

    let first = await OverlaySettingsStore(userDefaults: defaults)
    await MainActor.run {
        first.showIsland = false
        first.expandOnHover = false
        first.showBottomLyrics = false
        first.showTranslation = false
        first.useArtworkColors = false
        first.enableTrackAnimation = false
        first.hideInFullScreen = true
        first.reduceMotion = true
        first.widthMode = .default
        first.lineMode = .double
        first.lyricsAlignment = .trailing
    }

    let second = await OverlaySettingsStore(userDefaults: defaults)
    #expect(await second.showIsland == false)
    #expect(await second.expandOnHover == false)
    #expect(await second.showBottomLyrics == false)
    #expect(await second.showTranslation == false)
    #expect(await second.useArtworkColors == false)
    #expect(await second.enableTrackAnimation == false)
    #expect(await second.hideInFullScreen == true)
    #expect(await second.reduceMotion == true)
    #expect(await second.widthMode == .default)
    #expect(await second.lineMode == .double)
    #expect(await second.lyricsAlignment == .trailing)
}

// MARK: - Width modes

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

@Test func defaultWidthIsConstant() async throws {
    let settings = await OverlaySettingsStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
    let engine = LyricsLayoutEngine()

    let layout = await MainActor.run {
        settings.widthMode = .default
        return engine.makeLayout(
            track: .placeholder,
            currentLine: TimedLyricLine(startTime: 0, text: "anything"),
            nextLine: nil,
            settings: settings,
            isExpanded: false
        )
    }

    #expect(layout.collapsedWidth == 286)
}

// MARK: - No lyrics / missing translation

@Test func handlesNoLyricsGracefully() async throws {
    let store = await OverlaySettingsStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
    let state = await LyricsOverlayState(settings: store)

    await state.apply(
        snapshot: NowPlayingSnapshot(
            track: .placeholder,
            lyrics: [],
            progress: 0,
            isPlaying: true
        )
    )

    #expect(await state.activeLine == nil)
    #expect(await state.upcomingLine == nil)
    #expect(await state.previousLine == nil)
}

@Test func handlesLyricsWithoutTranslation() async throws {
    let store = await OverlaySettingsStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
    let state = await LyricsOverlayState(settings: store)

    await MainActor.run { store.showTranslation = true }

    let lyrics = [
        TimedLyricLine(startTime: 0, endTime: 5, text: "no translation here"),
        TimedLyricLine(startTime: 5, endTime: 10, text: "also none")
    ]

    await state.apply(
        snapshot: NowPlayingSnapshot(track: .placeholder, lyrics: lyrics, progress: 1, isPlaying: true)
    )

    #expect(await state.activeLine?.translation == nil)
    #expect(await state.activeLine?.text == "no translation here")
}

// MARK: - Track transition

@Test func trackChangeTriggersTrackTransitionPhase() async throws {
    let store = await OverlaySettingsStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
    let state = await LyricsOverlayState(settings: store)

    let trackA = NowPlayingTrack(
        id: "a", title: "A", artist: "Artist", album: "Album",
        accentColorHex: "#FF0000", secondaryColorHex: "#00FF00",
        duration: 30, artworkSymbol: "music.note"
    )
    let trackB = NowPlayingTrack(
        id: "b", title: "B", artist: "Artist", album: "Album",
        accentColorHex: "#0000FF", secondaryColorHex: "#FFFF00",
        duration: 30, artworkSymbol: "music.note"
    )

    let lyrics = [TimedLyricLine(startTime: 0, endTime: 10, text: "test")]

    await state.apply(
        snapshot: NowPlayingSnapshot(track: trackA, lyrics: lyrics, progress: 1, isPlaying: true)
    )

    let tokenBefore = await state.presentation.trackTransitionToken

    await state.apply(
        snapshot: NowPlayingSnapshot(track: trackB, lyrics: lyrics, progress: 0, isPlaying: true)
    )

    let tokenAfter = await state.presentation.trackTransitionToken
    let phase = await state.phase

    #expect(tokenAfter > tokenBefore)
    #expect(phase == .trackTransition)
}

@Test func trackChangeWithoutAnimationSkipsTransitionPhase() async throws {
    let store = await OverlaySettingsStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
    await MainActor.run { store.enableTrackAnimation = false }
    let presentation = await OverlayPresentationState()

    let trackA = NowPlayingTrack(
        id: "a", title: "A", artist: "A", album: "A",
        accentColorHex: "#FF0000", secondaryColorHex: "#00FF00",
        duration: 30, artworkSymbol: "music.note"
    )
    let trackB = NowPlayingTrack(
        id: "b", title: "B", artist: "B", album: "B",
        accentColorHex: "#0000FF", secondaryColorHex: "#FFFF00",
        duration: 30, artworkSymbol: "music.note"
    )

    let lyrics = [TimedLyricLine(startTime: 0, endTime: 10, text: "x")]

    await presentation.ingest(
        snapshot: NowPlayingSnapshot(track: trackA, lyrics: lyrics, progress: 1, isPlaying: true),
        animateTrackChanges: false
    )
    await presentation.ingest(
        snapshot: NowPlayingSnapshot(track: trackB, lyrics: lyrics, progress: 0, isPlaying: true),
        animateTrackChanges: false
    )

    let phase = await presentation.phase
    #expect(phase != .trackTransition)
}

// MARK: - Lyric transition

@Test func lyricChangeTriggersLyricTransitionPhase() async throws {
    let store = await OverlaySettingsStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
    let state = await LyricsOverlayState(settings: store)
    let lyrics = [
        TimedLyricLine(startTime: 0, endTime: 4, text: "one"),
        TimedLyricLine(startTime: 4, endTime: 8, text: "two")
    ]

    await state.apply(
        snapshot: NowPlayingSnapshot(track: .placeholder, lyrics: lyrics, progress: 1, isPlaying: true)
    )
    let tokenBefore = await state.presentation.lyricTransitionToken

    await state.apply(
        snapshot: NowPlayingSnapshot(track: .placeholder, lyrics: lyrics, progress: 5, isPlaying: true)
    )
    let tokenAfter = await state.presentation.lyricTransitionToken

    #expect(tokenAfter > tokenBefore)
    #expect(await state.activeLine?.text == "two")
}

// MARK: - Phase settle

@Test func phaseSettlesAfterTransition() async throws {
    let presentation = await OverlayPresentationState()

    await presentation.setExpanded(true)
    #expect(await presentation.phase == .hoverExpanding)

    try await Task.sleep(nanoseconds: 300_000_000)
    #expect(await presentation.phase == .expanded)
}

// MARK: - Theme engine

@Test func themeRespectsArtworkColorSetting() async throws {
    let store = await OverlaySettingsStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
    let engine = LyricsThemeEngine()

    let themeWithColor = await MainActor.run {
        store.useArtworkColors = true
        return engine.makeTheme(for: .placeholder, settings: store)
    }

    let themeWithoutColor = await MainActor.run {
        store.useArtworkColors = false
        return engine.makeTheme(for: .placeholder, settings: store)
    }

    #expect(themeWithColor.accentColor != themeWithoutColor.accentColor)
}

// MARK: - Layout expanded sizes

@Test func expandedSizeAdaptsToTranslationAndLineMode() async throws {
    let settings = await OverlaySettingsStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
    let engine = LyricsLayoutEngine()
    let line = TimedLyricLine(startTime: 0, text: "test line")

    let baseLayout = await MainActor.run {
        settings.showTranslation = false
        settings.lineMode = .single
        return engine.makeLayout(track: .placeholder, currentLine: line, nextLine: nil, settings: settings, isExpanded: true)
    }

    let withTranslation = await MainActor.run {
        settings.showTranslation = true
        settings.lineMode = .single
        return engine.makeLayout(track: .placeholder, currentLine: line, nextLine: nil, settings: settings, isExpanded: true)
    }

    let withDouble = await MainActor.run {
        settings.showTranslation = false
        settings.lineMode = .double
        return engine.makeLayout(track: .placeholder, currentLine: line, nextLine: nil, settings: settings, isExpanded: true)
    }

    #expect(withTranslation.expandedSize.height > baseLayout.expandedSize.height)
    #expect(withDouble.expandedSize.height > baseLayout.expandedSize.height)
}

// MARK: - Lyrics cache

@Test func inMemoryCacheStoresAndRetrievesLyrics() async throws {
    let cache = InMemoryLyricsCache()
    let lyrics = [TimedLyricLine(startTime: 0, text: "cached")]

    #expect(cache.lyrics(for: "track1") == nil)

    cache.store(lyrics, for: "track1")
    let retrieved = cache.lyrics(for: "track1")

    #expect(retrieved?.count == 1)
    #expect(retrieved?.first?.text == "cached")
}

// MARK: - Toggle helpers

@Test func settingsToggleHelpers() async throws {
    let store = await OverlaySettingsStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)

    #expect(await store.showIsland == true)
    await MainActor.run { store.toggleIslandVisibility() }
    #expect(await store.showIsland == false)

    #expect(await store.showBottomLyrics == true)
    await MainActor.run { store.toggleBottomLyrics() }
    #expect(await store.showBottomLyrics == false)

    #expect(await store.showTranslation == true)
    await MainActor.run { store.toggleTranslation() }
    #expect(await store.showTranslation == false)
}
