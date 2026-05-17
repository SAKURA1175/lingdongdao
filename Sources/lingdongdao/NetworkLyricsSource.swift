import Foundation

// MARK: - URLSession Timeout Helper

private extension URLSession {
    static func withTimeout(_ seconds: TimeInterval) -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = seconds
        config.timeoutIntervalForResource = seconds
        return URLSession(configuration: config)
    }
}

// MARK: - NetworkLyricsSource

@MainActor
final class NetworkLyricsSource: LyricsSource {

    /// Race all available sources. Return the first non-empty result, with an
    /// overall hard deadline so the caller never waits more than `globalTimeout`.
    func lyrics(for track: NowPlayingTrack) async throws -> [TimedLyricLine] {
        let globalTimeout: TimeInterval = 8

        return try await withThrowingTaskGroup(of: [TimedLyricLine].self) { group in

            // Source 1 – LRCLIB (fast, global music database with word-level timestamps)
            group.addTask {
                (try? await LRCLIBSource.fetch(track: track)) ?? []
            }

            // Source 2 – Netease (great Chinese-language + translation coverage)
            group.addTask {
                (try? await NeteaseSource.fetch(track: track)) ?? []
            }

            // Source 3 – QQ Music (wide domestic coverage, good fallback)
            group.addTask {
                (try? await QQMusicSource.fetch(track: track)) ?? []
            }

            // Hard deadline task — throws after globalTimeout seconds
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(globalTimeout * 1_000_000_000))
                throw LyricsError.timeout
            }

            defer { group.cancelAll() }

            // Return first non-empty result or throw if timeout wins
            for try await result in group {
                if !result.isEmpty {
                    return result
                }
            }
            return []
        }
    }
}

// MARK: - Error

enum LyricsError: Error {
    case timeout
    case notFound
    case decodingFailed
}

// MARK: - Source 1: LRCLIB

private struct LRCLIBSource {
    static func fetch(track: NowPlayingTrack) async throws -> [TimedLyricLine] {
        let session = URLSession.withTimeout(5)

        // Try exact match first
        if let lines = try? await fetchExact(track: track, session: session), !lines.isEmpty {
            return lines
        }

        // Fallback: search endpoint
        return (try? await fetchSearch(track: track, session: session)) ?? []
    }

    private static func fetchExact(track: NowPlayingTrack, session: URLSession) async throws -> [TimedLyricLine] {
        var comps = URLComponents(string: "https://lrclib.net/api/get")!
        comps.queryItems = [
            URLQueryItem(name: "artist_name", value: track.artist),
            URLQueryItem(name: "track_name", value: track.title),
            URLQueryItem(name: "album_name", value: track.album),
            URLQueryItem(name: "duration",    value: track.duration > 0 ? String(Int(track.duration)) : nil)
        ].compactMap { $0.value != nil ? $0 : nil }

        guard let url = comps.url else { return [] }
        var req = URLRequest(url: url)
        req.setValue("lingdongdao/1.0 (https://github.com/SAKURA1175/lingdongdao)", forHTTPHeaderField: "Lrclib-Client")

        let (data, response) = try await session.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }

        struct LRCLIBTrack: Decodable {
            let syncedLyrics: String?
            let plainLyrics: String?
        }
        let result = try JSONDecoder().decode(LRCLIBTrack.self, from: data)
        let lrc = result.syncedLyrics ?? result.plainLyrics ?? ""
        return LRCParser.parse(lrc: lrc)
    }

    private static func fetchSearch(track: NowPlayingTrack, session: URLSession) async throws -> [TimedLyricLine] {
        var comps = URLComponents(string: "https://lrclib.net/api/search")!
        comps.queryItems = [
            URLQueryItem(name: "artist_name", value: track.artist),
            URLQueryItem(name: "track_name",  value: track.title)
        ]
        guard let url = comps.url else { return [] }
        var req = URLRequest(url: url)
        req.setValue("lingdongdao/1.0 (https://github.com/SAKURA1175/lingdongdao)", forHTTPHeaderField: "Lrclib-Client")

        let (data, response) = try await session.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }

        struct LRCLIBSearchItem: Decodable {
            let syncedLyrics: String?
            let plainLyrics: String?
            let duration: Double?
        }
        let items = try JSONDecoder().decode([LRCLIBSearchItem].self, from: data)

        // Pick best match: prefer synced lyrics, prefer closer duration
        let sorted = items
            .filter { ($0.syncedLyrics ?? $0.plainLyrics) != nil }
            .sorted { a, b in
                let aDuration = abs((a.duration ?? 0) - track.duration)
                let bDuration = abs((b.duration ?? 0) - track.duration)
                return aDuration < bDuration
            }

        guard let best = sorted.first else { return [] }
        let lrc = best.syncedLyrics ?? best.plainLyrics ?? ""
        return LRCParser.parse(lrc: lrc)
    }
}

// MARK: - Source 2: Netease Music

private struct NeteaseSource {
    static func fetch(track: NowPlayingTrack) async throws -> [TimedLyricLine] {
        let session = URLSession.withTimeout(5)

        let query = "\(track.title) \(track.artist)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let searchURL = URL(string: "https://music.163.com/api/search/get?s=\(query)&type=1&limit=10")!
        var req = URLRequest(url: searchURL)
        req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        req.setValue("https://music.163.com", forHTTPHeaderField: "Referer")

        let (searchData, _) = try await session.data(for: req)

        struct SearchResp: Decodable {
            struct Result: Decodable {
                struct Song: Decodable {
                    struct Artist: Decodable { let name: String? }
                    let id: Int
                    let name: String?
                    let artists: [Artist]?
                    let duration: Int? // ms
                }
                let songs: [Song]?
            }
            let result: Result?
        }

        let decoded = try JSONDecoder().decode(SearchResp.self, from: searchData)
        guard let songs = decoded.result?.songs, !songs.isEmpty else { return [] }

        // Score each result: title match + artist match + duration proximity
        let queryTitle  = track.title.lowercased()
        let queryArtist = track.artist.lowercased()
        let queryWords  = Set(
            "\(track.title) \(track.artist)"
                .lowercased()
                .components(separatedBy: .whitespaces)
                .filter { $0.count > 1 }
        )

        var bestID: Int? = nil
        var bestScore: Double = -1

        for song in songs {
            let sName    = (song.name ?? "").lowercased()
            let sArtists = (song.artists?.compactMap { $0.name?.lowercased() } ?? []).joined(separator: " ")
            let resultStr = sName + " " + sArtists

            // Word overlap score
            let overlap = queryWords.filter { resultStr.contains($0) }.count
            guard overlap > 0 else { continue }

            var score = Double(overlap)

            // Bonus for exact title or artist match
            if sName.contains(queryTitle) || queryTitle.contains(sName) { score += 2 }
            if sArtists.contains(queryArtist) { score += 1.5 }

            // Duration similarity bonus (duration is in ms)
            if let dur = song.duration, track.duration > 0 {
                let diff = abs(Double(dur) / 1000.0 - track.duration)
                if diff < 2 { score += 2 }
                else if diff < 5 { score += 1 }
            }

            if score > bestScore {
                bestScore = score
                bestID = song.id
            }
        }

        guard let songID = bestID else { return [] }

        let lyricURL = URL(string: "https://music.163.com/api/song/lyric?os=pc&id=\(songID)&lv=-1&kv=-1&tv=-1")!
        let (lyricData, _) = try await session.data(from: lyricURL)

        struct LyricResp: Decodable {
            struct LyricData: Decodable { let lyric: String? }
            let lrc: LyricData?
            let tlyric: LyricData?
        }

        let lyricResult = try JSONDecoder().decode(LyricResp.self, from: lyricData)
        let lrc    = lyricResult.lrc?.lyric    ?? ""
        let tlyric = lyricResult.tlyric?.lyric ?? ""

        return LRCParser.parse(lrc: lrc, tlyric: tlyric)
    }
}

// MARK: - Source 3: QQ Music

private struct QQMusicSource {
    static func fetch(track: NowPlayingTrack) async throws -> [TimedLyricLine] {
        let session = URLSession.withTimeout(5)

        // Step 1: Search for song
        let query = "\(track.title) \(track.artist)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        guard let searchURL = URL(string: "https://c.y.qq.com/soso/fcgi-bin/client_search_cp?ct=24&qqmusic_ver=1298&new_json=1&remoteplace=txt.yqq.top&searchid=60&t=0&aggr=1&cr=1&catZhida=1&lossless=0&flag_qc=0&p=1&n=10&w=\(query)&g_tk=5381&loveflag=0&format=json&inCharset=utf8&outCharset=utf-8&notice=0&platform=yqq&needNewCode=0") else { return [] }

        var req = URLRequest(url: searchURL)
        req.setValue("https://y.qq.com", forHTTPHeaderField: "Referer")
        req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }

        struct QQSearchResp: Decodable {
            struct Data: Decodable {
                struct Body: Decodable {
                    struct Song: Decodable {
                        struct List: Decodable {
                            struct Singer: Decodable { let name: String? }
                            let songmid: String?
                            let songname: String?
                            let singer: [Singer]?
                            let interval: Int? // seconds
                        }
                        let list: [List]?
                    }
                    let song: Song?
                }
                let body: Body?
            }
            let data: Data?
        }

        let decoded = try JSONDecoder().decode(QQSearchResp.self, from: data)
        guard let songs = decoded.data?.body?.song?.list, !songs.isEmpty else { return [] }

        let queryTitle  = track.title.lowercased()
        let queryArtist = track.artist.lowercased()

        var bestMid: String? = nil
        var bestScore: Double = -1

        for song in songs {
            let sName    = (song.songname ?? "").lowercased()
            let sArtists = (song.singer?.compactMap { $0.name?.lowercased() } ?? []).joined(separator: " ")

            guard sName.contains(queryTitle) || queryTitle.contains(sName) ||
                  sArtists.contains(queryArtist) else { continue }

            var score = 0.0
            if sName.contains(queryTitle) { score += 2 }
            if sArtists.contains(queryArtist) { score += 1.5 }

            if let dur = song.interval, track.duration > 0 {
                let diff = abs(Double(dur) - track.duration)
                if diff < 2 { score += 2 }
                else if diff < 5 { score += 1 }
            }

            if score > bestScore, let mid = song.songmid {
                bestScore = score
                bestMid = mid
            }
        }

        guard let mid = bestMid else { return [] }

        // Step 2: Fetch lyrics by songmid
        guard let lyricURL = URL(string: "https://c.y.qq.com/lyric/fcgi-bin/fcg_query_lyric_new.fcg?songmid=\(mid)&g_tk=5381&format=json&inCharset=utf8&outCharset=utf-8&notice=0&platform=yqq&needNewCode=0") else { return [] }

        var lyricReq = URLRequest(url: lyricURL)
        lyricReq.setValue("https://y.qq.com", forHTTPHeaderField: "Referer")
        lyricReq.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (lyricData, _) = try await session.data(for: lyricReq)

        struct QQLyricResp: Decodable {
            let lyric: String?
            let trans: String?
        }

        let lyricResult = try JSONDecoder().decode(QQLyricResp.self, from: lyricData)

        // QQ Music returns Base64-encoded LRC
        let lrc: String
        if let encoded = lyricResult.lyric,
           let decoded64 = Data(base64Encoded: encoded),
           let text = String(data: decoded64, encoding: .utf8) {
            lrc = text
        } else {
            return []
        }

        let tlyric: String
        if let encoded = lyricResult.trans,
           let decoded64 = Data(base64Encoded: encoded),
           let text = String(data: decoded64, encoding: .utf8) {
            tlyric = text
        } else {
            tlyric = ""
        }

        return LRCParser.parse(lrc: lrc, tlyric: tlyric)
    }
}

// MARK: - LRC Parser

struct LRCParser {
    static func parse(lrc: String, tlyric: String? = nil) -> [TimedLyricLine] {
        var mainDict: [TimeInterval: String] = [:]
        var transDict: [TimeInterval: String] = [:]

        for line in lrc.components(separatedBy: .newlines) {
            parseLine(line, into: &mainDict)
        }
        if let tlyric {
            for line in tlyric.components(separatedBy: .newlines) {
                parseLine(line, into: &transDict)
            }
        }

        let sortedTimes = mainDict.keys.sorted()
        var results: [TimedLyricLine] = []

        for (index, time) in sortedTimes.enumerated() {
            let text = mainDict[time]?.trimmingCharacters(in: .whitespaces) ?? ""
            if text.isEmpty { continue }

            let trans   = transDict[time]?.trimmingCharacters(in: .whitespaces)
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
        let pattern = "\\[(\\d{2,}):(\\d{2})(?:\\.(\\d{1,3}))?\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let nsLine = line as NSString
        let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
        guard !matches.isEmpty else { return }

        let textStart = matches.last!.range.location + matches.last!.range.length
        let text = nsLine.substring(from: textStart)

        for match in matches {
            let minStr = nsLine.substring(with: match.range(at: 1))
            let secStr = nsLine.substring(with: match.range(at: 2))
            var msStr  = "0"
            if match.range(at: 3).location != NSNotFound {
                msStr = nsLine.substring(with: match.range(at: 3))
            }
            if msStr.count == 1 { msStr += "00" }
            else if msStr.count == 2 { msStr += "0" }

            let min = TimeInterval(minStr) ?? 0
            let sec = TimeInterval(secStr) ?? 0
            let ms  = TimeInterval(msStr)  ?? 0
            dict[(min * 60) + sec + (ms / 1000.0)] = text
        }
    }
}
