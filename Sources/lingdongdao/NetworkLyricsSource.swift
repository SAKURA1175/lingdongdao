import Foundation

@MainActor
final class NetworkLyricsSource: LyricsSource {
    
    func lyrics(for track: NowPlayingTrack) async throws -> [TimedLyricLine] {
        if let lines = try? await fetchFromNetease(track: track), !lines.isEmpty {
            return lines
        }
        return []
    }
    
    // MARK: - Netease
    
    private func fetchFromNetease(track: NowPlayingTrack) async throws -> [TimedLyricLine]? {
        let query = "\(track.title) \(track.artist)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let searchURL = URL(string: "http://music.163.com/api/search/get?s=\(query)&type=1&limit=5")!
        
        var request = URLRequest(url: searchURL)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)", forHTTPHeaderField: "User-Agent")
        
        let (searchData, _) = try await URLSession.shared.data(for: request)
        
        struct NeteaseSearchResponse: Decodable {
            let result: NeteaseSearchResult?
        }
        struct NeteaseSearchResult: Decodable {
            let songs: [NeteaseSong]?
        }
        struct NeteaseArtist: Decodable {
            let name: String?
        }
        struct NeteaseSong: Decodable {
            let id: Int
            let name: String?
            let artists: [NeteaseArtist]?
        }
        
        let searchResult = try JSONDecoder().decode(NeteaseSearchResponse.self, from: searchData)
        guard let songs = searchResult.result?.songs else {
            return nil
        }
        
        let queryWords = Set("\(track.title) \(track.artist)".lowercased().components(separatedBy: .whitespaces).filter { $0.count > 1 })
        var matchedSongID: Int? = nil
        
        for song in songs {
            let songName = song.name?.lowercased() ?? ""
            let artistNames = song.artists?.compactMap { $0.name?.lowercased() } ?? []
            let resultString = (songName + " " + artistNames.joined(separator: " ")).lowercased()
            
            // Check if there is any meaningful word overlap between our query and the Netease result.
            // This easily filters out completely unrelated 'Garbage Fallback' songs.
            let hasOverlap = queryWords.contains { word in
                resultString.contains(word)
            }
            
            if hasOverlap {
                matchedSongID = song.id
                break
            }
        }
        
        guard let songID = matchedSongID else {
            return nil
        }
        
        let lyricURL = URL(string: "http://music.163.com/api/song/lyric?os=pc&id=\(songID)&lv=-1&kv=-1&tv=-1")!
        let (lyricData, _) = try await URLSession.shared.data(from: lyricURL)
        
        struct NeteaseLyricResponse: Decodable {
            let lrc: NeteaseLyricData?
            let tlyric: NeteaseLyricData?
        }
        struct NeteaseLyricData: Decodable {
            let lyric: String?
        }
        
        let lyricResult = try JSONDecoder().decode(NeteaseLyricResponse.self, from: lyricData)
        
        let lrcText = lyricResult.lrc?.lyric ?? ""
        let tlyricText = lyricResult.tlyric?.lyric ?? ""
        
        return LRCParser.parse(lrc: lrcText, tlyric: tlyricText)
    }
}

// MARK: - LRC Parser

struct LRCParser {
    static func parse(lrc: String, tlyric: String? = nil) -> [TimedLyricLine] {
        var mainDict: [TimeInterval: String] = [:]
        var transDict: [TimeInterval: String] = [:]
        
        // Parse main lyrics
        for line in lrc.components(separatedBy: .newlines) {
            parseLine(line, into: &mainDict)
        }
        
        // Parse translation if available
        if let tlyric = tlyric {
            for line in tlyric.components(separatedBy: .newlines) {
                parseLine(line, into: &transDict)
            }
        }
        
        let sortedTimes = mainDict.keys.sorted()
        var results: [TimedLyricLine] = []
        
        for (index, time) in sortedTimes.enumerated() {
            let text = mainDict[time]?.trimmingCharacters(in: .whitespaces) ?? ""
            if text.isEmpty { continue }
            
            let trans = transDict[time]?.trimmingCharacters(in: .whitespaces)
            let endTime = index < sortedTimes.count - 1 ? sortedTimes[index + 1] : nil
            
            results.append(TimedLyricLine(
                startTime: time,
                endTime: endTime,
                text: text,
                translation: trans?.isEmpty == false ? trans : nil
            ))
        }
        
        return results
    }
    
    private static func parseLine(_ line: String, into dict: inout [TimeInterval: String]) {
        // Example: [00:12.34]Lyric text
        // Match timestamps like [mm:ss.xx]
        let pattern = "\\[(\\d{2,}):(\\d{2})(?:\\.(\\d{1,3}))?\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        
        let nsString = line as NSString
        let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsString.length))
        
        if matches.isEmpty { return }
        
        // Extract text (everything after the last matched timestamp bracket)
        let lastMatch = matches.last!
        let textStart = lastMatch.range.location + lastMatch.range.length
        let text = nsString.substring(from: textStart).trimmingCharacters(in: .whitespaces)
        
        for match in matches {
            let minStr = nsString.substring(with: match.range(at: 1))
            let secStr = nsString.substring(with: match.range(at: 2))
            
            var msStr = "0"
            if match.range(at: 3).location != NSNotFound {
                msStr = nsString.substring(with: match.range(at: 3))
            }
            
            // Normalize ms string (e.g. "3" -> 300ms, "34" -> 340ms)
            if msStr.count == 1 { msStr += "00" }
            else if msStr.count == 2 { msStr += "0" }
            
            let min = TimeInterval(minStr) ?? 0
            let sec = TimeInterval(secStr) ?? 0
            let ms = TimeInterval(msStr) ?? 0
            
            let time = (min * 60) + sec + (ms / 1000.0)
            dict[time] = text
        }
    }
}
