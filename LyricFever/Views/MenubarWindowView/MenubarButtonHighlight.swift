//
//  MenubarButtonHighlight.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-15.
//

import SwiftUI

enum MenubarButtonHighlight {
    case activateSpotify
    case activateAppleMusic
    case rewind
    case play
    case pause
    case forward
    case showMenuBarLyrics
    case hideMenuBarLyrics
    case menuBarLyricsUnavailable
    case enableFullscreen
    case showKaraokeWindow
    case hideKaraokeWindow
    case karaokeWindowUnavailable
    case refreshLyrics
    case refreshingLyrics
    case search
    case translate
    case translateEnabled
    case translationFail
    case translationLoading
    case translationUnavailable
    case upload
    case delete
    case quit
    case moreOptions
    
    case none
    
    
    var description: LocalizedStringKey {
        switch self {
            case .activateSpotify:
                LocalizedStringKey("Open Spotify")
            case .activateAppleMusic:
                LocalizedStringKey("Open Apple Music")
            case .rewind:
                LocalizedStringKey("Rewind")
            case .play:
                LocalizedStringKey("Play (spacebar)")
            case .pause:
                LocalizedStringKey("Pause (spacebar)")
            case .forward:
                LocalizedStringKey("Forward")
            case .showMenuBarLyrics:
                LocalizedStringKey("Show menu bar lyrics")
            case .hideMenuBarLyrics:
                LocalizedStringKey("Hide menu bar lyrics")
            case .menuBarLyricsUnavailable:
                LocalizedStringKey("Menu bar lyrics unavailable")
            case .enableFullscreen:
                LocalizedStringKey("Open Fullscreen")
            case .showKaraokeWindow:
                LocalizedStringKey("Show karaoke window")
            case .hideKaraokeWindow:
                LocalizedStringKey("Hide karaoke window")
            case .karaokeWindowUnavailable:
                LocalizedStringKey("Karaoke window unavailable")
            case .refreshLyrics:
                LocalizedStringKey("Redownload lyrics")
            case .refreshingLyrics:
                LocalizedStringKey("Refreshing Lyrics...")
            case .search:
                LocalizedStringKey("Manual lyric search")
            case .translate:
                LocalizedStringKey("Translation options")
            case .translateEnabled:
                LocalizedStringKey("Translation Enabled")
            case .translationFail:
                LocalizedStringKey("Translation Failure")
            case .translationLoading:
                LocalizedStringKey("Translating...")
            case .translationUnavailable:
                LocalizedStringKey("Translation Unavailable")
            case .upload:
                LocalizedStringKey("Upload LRC File")
            case .delete:
                LocalizedStringKey("Delete Lyrics")
            case .quit:
                LocalizedStringKey("Quit LyricChill (⌘ + Q)")
            case .moreOptions:
                LocalizedStringKey("More Options")
            case .none:
                ""
        }
    }
}
