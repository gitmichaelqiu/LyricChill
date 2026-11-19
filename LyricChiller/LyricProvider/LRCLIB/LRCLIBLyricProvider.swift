//
//  LRCLIBLyricProvider.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-06-16.
//

import Foundation

class LRCLIBLyricProvider: LyricProvider {
    var providerName = "LRCLIB Lyric Provider"
    // LRCLIB User Agent
    let LRCLIBUserAgentConfig = URLSessionConfiguration.default
    let LRCLIBUserAgentSession: URLSession
    
    init() {
//        LRCLIBUserAgentConfig.httpAdditionalHeaders = ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 15_6_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Safari/605.1.15"]
        LRCLIBUserAgentConfig.httpAdditionalHeaders = ["User-Agent": "LyricChiller v3.3 (https://github.com/gitmichaelqiu/LyricChiller)"]
        LRCLIBUserAgentSession = URLSession(configuration: LRCLIBUserAgentConfig)
    }
    
    func fetchNetworkLyrics(trackName: String, trackID: String, currentlyPlayingArtist: String?, currentAlbumName: String?) async throws -> NetworkFetchReturn {
        guard let currentlyPlayingArtist, let currentAlbumName else {
            print("artist or album missing")
            return NetworkFetchReturn(lyrics: [], colorData: nil)
        }
        guard let url = makeComponents(path: "/api/get", items: [
            URLQueryItem(name: "artist_name", value: currentlyPlayingArtist),
            URLQueryItem(name: "track_name", value: trackName),
            URLQueryItem(name: "album_name", value: currentAlbumName)
        ]).url else {
            return NetworkFetchReturn(lyrics: [], colorData: nil)
        }
        print("LRCLIB /api/get: \(url.absoluteString)")
        let req = URLRequest(url: url)
        var exactMatch: LRCLIBLyrics?
        do {
            let (data, response) = try await LRCLIBUserAgentSession.data(for: req)
            if let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) {
                exactMatch = try JSONDecoder().decode(LRCLIBLyrics.self, from: data)
            } else {
                print("LRCLIB /api/get returned a non-success response")
            }
        } catch {
            print("LRCLIB /api/get failed: \(error)")
        }

        if let exactMatch, !exactMatch.lyrics.isEmpty {
            return NetworkFetchReturn(lyrics: exactMatch.lyrics, colorData: nil)
        }

        if exactMatch?.plainLyrics?.isEmpty == false {
            print("LRCLIB exact match has plain lyrics only; searching for a synced version")
        }

        let searchResults = try await fetchSearchResults(trackName: trackName, artistName: currentlyPlayingArtist)
        guard let syncedMatch = bestSyncedMatch(
            in: searchResults,
            trackName: trackName,
            artistName: currentlyPlayingArtist,
            albumName: currentAlbumName,
            duration: exactMatch?.duration
        ) else {
            return NetworkFetchReturn(lyrics: [], colorData: nil)
        }

        print("LRCLIB: found a matching synced lyric record (\(syncedMatch.trackName), \(syncedMatch.albumName))")
        return NetworkFetchReturn(lyrics: syncedMatch.lyrics, colorData: nil)
    }
    
    func fetchNetworkLyrics2(trackName: String, trackID: String, currentlyPlayingArtist: String?, currentAlbumName: String?) async throws -> NetworkFetchReturn {
        try await fetchNetworkLyrics(
            trackName: trackName,
            trackID: trackID,
            currentlyPlayingArtist: currentlyPlayingArtist,
            currentAlbumName: currentAlbumName
        )
    }
    
    func search(trackName: String, artistName: String) async throws -> [SongResult] {
        guard let url = makeComponents(path: "/api/search", items: [
            URLQueryItem(name: "track_name", value: trackName),
            URLQueryItem(name: "artist_name", value: artistName)
        ]).url else {
            print("MassSearch: LRCLIB: failed to generate URl")
            return []
        }
        print("LRCLIB /api/search: \(url.absoluteString)")
        let req = URLRequest(url: url)
        print("The request is \(req)")
        let urlResponseAndData = try await LRCLIBUserAgentSession.data(for: req)
        let lrcLyrics = try JSONDecoder().decode(PluralLRCLIBLyrics.self, from: urlResponseAndData.0)
        print("lrc downloaded")
        var results: [SongResult] = []
        for lyric in lrcLyrics.lyrics {
            print("lrc lyric: \(lyric.name)")
            results.append(SongResult(lyricType: "LRCLIB", songName: lyric.trackName, albumName: lyric.albumName, artistName: lyric.artistName, lyrics: lyric.lyrics))
        }
        return results
    }
    
    func makeComponents(path: String, items: [URLQueryItem]) -> URLComponents {
        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = "lrclib.net"
        comps.path = path
        comps.queryItems = items
        return comps
    }

    private func fetchSearchResults(trackName: String, artistName: String) async throws -> [LRCLIBLyrics] {
        guard let url = makeComponents(path: "/api/search", items: [
            URLQueryItem(name: "track_name", value: trackName),
            URLQueryItem(name: "artist_name", value: artistName)
        ]).url else {
            return []
        }

        let (data, response) = try await LRCLIBUserAgentSession.data(for: URLRequest(url: url))
        guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
            print("LRCLIB /api/search returned a non-success response")
            return []
        }

        return try JSONDecoder().decode(PluralLRCLIBLyrics.self, from: data).lyrics
    }

    private func bestSyncedMatch(
        in results: [LRCLIBLyrics],
        trackName: String,
        artistName: String,
        albumName: String,
        duration: Double?
    ) -> LRCLIBLyrics? {
        let normalizedTrackName = normalizedMetadata(trackName)
        let normalizedArtistName = normalizedMetadata(artistName)

        let eligibleResults = results.filter { result in
            let resultTrackName = result.trackName.replacingOccurrences(
                of: #"\s*\(Paused\)$"#,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )

            guard normalizedMetadata(resultTrackName) == normalizedTrackName,
                  normalizedMetadata(result.artistName) == normalizedArtistName,
                  !result.lyrics.isEmpty else {
                return false
            }

            guard let duration else { return true }
            return abs(result.duration - duration) <= 15
        }

        return eligibleResults.min { left, right in
            let leftAlbumMatches = normalizedMetadata(left.albumName) == normalizedMetadata(albumName)
            let rightAlbumMatches = normalizedMetadata(right.albumName) == normalizedMetadata(albumName)
            if leftAlbumMatches != rightAlbumMatches {
                return leftAlbumMatches
            }

            if let duration {
                let leftDurationDifference = abs(left.duration - duration)
                let rightDurationDifference = abs(right.duration - duration)
                if leftDurationDifference != rightDurationDifference {
                    return leftDurationDifference < rightDurationDifference
                }
            }

            return normalizedMetadata(left.trackName) == normalizedTrackName
                && normalizedMetadata(right.trackName) != normalizedTrackName
        }
    }

    private func normalizedMetadata(_ value: String) -> String {
        let folded = value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        return String(folded.filter { $0.isLetter || $0.isNumber })
    }
}
