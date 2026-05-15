import Foundation
import AppKit

@MainActor
final class AppleMusicPlaybackSource: PlaybackSource, ObservableObject {
    private var timer: Timer?
    
    // Fallback/demo cover color
    private let defaultAccent = "#D81B60"
    private let defaultSecondary = "#FF8BA7"
    
    func start(_ onSnapshot: @escaping @MainActor (NowPlayingSnapshot) -> Void) {
        timer?.invalidate()
        
        // Polling Apple Music every 0.5 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.fetchMusicData(onSnapshot: onSnapshot)
            }
        }
        
        // Initial fetch
        fetchMusicData(onSnapshot: onSnapshot)
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    private func fetchMusicData(onSnapshot: @escaping @MainActor (NowPlayingSnapshot) -> Void) {
        let scriptSource = """
        tell application "System Events"
            set isRunning to (name of processes) contains "Music"
        end tell

        if isRunning then
            tell application "Music"
                if player state is playing then
                    set t to current track
                    return (name of t & "|||" & artist of t & "|||" & album of t & "|||" & duration of t & "|||" & player position & "|||" & id of t)
                else
                    return "PAUSED"
                end if
            end tell
        else
            return "NOT_RUNNING"
        end if
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: scriptSource) {
            let output = scriptObject.executeAndReturnError(&error)
            if error != nil {
                return
            }
            
            let resultString = output.stringValue ?? ""
            
            if resultString == "NOT_RUNNING" || resultString == "PAUSED" || resultString.isEmpty {
                return
            }
            
            let parts = resultString.components(separatedBy: "|||")
            if parts.count >= 6 {
                let title = parts[0]
                let artist = parts[1]
                let album = parts[2]
                let duration = TimeInterval(parts[3]) ?? 0
                let position = TimeInterval(parts[4]) ?? 0
                let trackID = parts[5]
                
                let track = NowPlayingTrack(
                    id: "apple_music_\(trackID)",
                    title: title,
                    artist: artist,
                    album: album,
                    accentColorHex: defaultAccent,
                    secondaryColorHex: defaultSecondary,
                    duration: duration,
                    artworkSymbol: "music.note"
                )
                
                onSnapshot(
                    NowPlayingSnapshot(
                        track: track,
                        lyrics: [], // Lyrics will be loaded by the controller via LyricsSource
                        progress: position,
                        isPlaying: true
                    )
                )
            }
        }
    }
}
