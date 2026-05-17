import Foundation
import AppKit

@MainActor
final class AppleMusicPlaybackSource: PlaybackSource, ObservableObject {
    private var timer: Timer?
    private let defaultAccent    = "#D81B60"
    private let defaultSecondary = "#FF8BA7"

    func start(_ onSnapshot: @escaping @MainActor (NowPlayingSnapshot) -> Void) {
        timer?.invalidate()
        // Use a slightly longer interval so we don't spam AppleScript
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.fetchInBackground(onSnapshot: onSnapshot)
        }
        // Initial fetch
        fetchInBackground(onSnapshot: onSnapshot)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // Run AppleScript on a background thread to avoid blocking the main actor,
    // then hop back to MainActor to deliver the snapshot.
    private func fetchInBackground(onSnapshot: @escaping @MainActor (NowPlayingSnapshot) -> Void) {
        Task.detached(priority: .utility) {
            let result = await Self.runAppleScript()
            guard let result else { return }
            await MainActor.run {
                onSnapshot(result)
            }
        }
    }

    private static func runAppleScript() async -> NowPlayingSnapshot? {
        // NSAppleScript must run on the main thread per Apple's docs, BUT
        // we want the *network* work to happen off the main actor.
        // The compromise: run the script on a dedicated serial queue so it
        // does not block the main run loop (URLSession callbacks land there).
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let scriptSource = """
                tell application "System Events"
                    set isRunning to (name of processes) contains "Music"
                end tell
                if isRunning then
                    tell application "Music"
                        if player state is playing then
                            set t to current track
                            return (name of t & "|||" & artist of t & "|||" & album of t & "|||" & duration of t & "|||" & player position)
                        else
                            return "PAUSED"
                        end if
                    end tell
                else
                    return "NOT_RUNNING"
                end if
                """

                var error: NSDictionary?
                guard let script = NSAppleScript(source: scriptSource) else {
                    continuation.resume(returning: nil)
                    return
                }
                let output = script.executeAndReturnError(&error)

                guard error == nil else {
                    continuation.resume(returning: nil)
                    return
                }

                let resultString = output.stringValue ?? ""
                guard resultString != "NOT_RUNNING",
                      resultString != "PAUSED",
                      !resultString.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let parts = resultString.components(separatedBy: "|||")
                guard parts.count >= 5 else {
                    continuation.resume(returning: nil)
                    return
                }

                let title    = parts[0].trimmingCharacters(in: .whitespaces)
                let artist   = parts[1].trimmingCharacters(in: .whitespaces)
                let album    = parts[2].trimmingCharacters(in: .whitespaces)
                let duration = TimeInterval(parts[3].trimmingCharacters(in: .whitespaces)) ?? 0
                let position = TimeInterval(parts[4].trimmingCharacters(in: .whitespaces)) ?? 0

                // Use a stable, human-readable ID so the same track is never re-fetched.
                // Apple Music's internal numeric ID can change between library re-indexes.
                let stableID = "\(title)_\(artist)".lowercased()
                    .components(separatedBy: .whitespacesAndNewlines).joined(separator: "_")

                let track = NowPlayingTrack(
                    id: stableID,
                    title: title,
                    artist: artist,
                    album: album,
                    accentColorHex: "#D81B60",
                    secondaryColorHex: "#FF8BA7",
                    duration: duration,
                    artworkSymbol: "music.note"
                )

                let snapshot = NowPlayingSnapshot(
                    track: track,
                    lyrics: [],
                    progress: position,
                    isPlaying: true
                )
                continuation.resume(returning: snapshot)
            }
        }
    }
}
