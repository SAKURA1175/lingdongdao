import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settingsStore = OverlaySettingsStore()
    lazy var overlayState = LyricsOverlayState(settings: settingsStore)
    lazy var overlayCoordinator = OverlayCoordinator(
        playbackSource: AppleMusicPlaybackSource(),
        lyricsSource: NetworkLyricsSource(),
        lyricsCache: InMemoryLyricsCache(),
        overlayState: overlayState
    )
    lazy var overlayController = LyricsOverlayController(
        state: overlayState,
        coordinator: overlayCoordinator
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        overlayController.showWindow()
    }

    func applicationWillTerminate(_ notification: Notification) {
        overlayController.stop()
    }
}
