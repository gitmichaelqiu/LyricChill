//
//  MusicBrainzArtworkService.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-26.
//


//
//  MusicBrainz.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-18.
//

import Foundation
import AppKit

class MusicBrainzArtworkService {
    static func findMbid(albumName: String, artistName: String) async -> String? {
        var components = URLComponents(string: "https://musicbrainz.org/ws/2/release/")
        components?.queryItems = [
            URLQueryItem(name: "query", value: "artist:\"\(artistName)\" AND release:\"\(albumName)\""),
            URLQueryItem(name: "fmt", value: "json")
        ]

        guard let url = components?.url,
              let (data, _) = try? await URLSession.shared.data(from: url),
              let response = try? JSONDecoder().decode(MusicBrainzReply.self, from: data) else {
            return nil
        }
        return response.releases.first?.id
    }
    
    static func artworkUrl(_ mbid: String) -> URL? {
        return URL(string:"https://coverartarchive.org/release/\(mbid)/front")
    }
    
    static func artworkImage(for mbid: String) async -> NSImage? {
        guard let artworkUrl = artworkUrl(mbid) else {
            print("\(#function) failed to url")
            return nil
        }
        do {
            let artwork = try await URLSession.shared.data(for: URLRequest(url: artworkUrl))
            return NSImage(data: artwork.0)
        } catch {
            print("\(#function) failed to download artwork \(error)")
            return nil
        }
    }
}
