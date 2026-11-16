//
//  SpotifyLyricsInMenubarApp.swift
//  SpotifyLyricsInMenubar
//
//  Created by Avi Wadhwa on 26/07/23.
//

import SwiftUI
import Translation
import LaunchAtLogin
import MenuBarExtraAccess

extension NSScreen {
    static var mainWidth: CGFloat {
        NSScreen.main?.frame.width ?? 1920
    }
    static var mainHeight: CGFloat {
        NSScreen.main?.frame.height ?? 1080
    }
}

@main
struct LyricChillerApp: App {
    @State var viewmodel = ViewModel.shared
    @AppStorage("showMenubarIcon") private var isMenuBarIconVisible = true
    @NSApplicationDelegateAdaptor(LyricChillerAppDelegate.self) private var appDelegate
    @Environment(\.openWindow) var openWindow
    @Environment(\.openURL) var openURL
    
    var body: some Scene {
        @Bindable var viewmodel = viewmodel

        MenuBarExtra(isInserted: $isMenuBarIconVisible) {
            MenubarWindowView()
                .environment(viewmodel)
        } label: {
            // Text(Image) Doesn't render propertly in MenubarExtra. Stupid Apple. Must resort to if/else
            MenubarLabelView()
                .environment(viewmodel)
            .task(id: viewmodel.currentlyPlaying) {
                guard let trackID = viewmodel.currentlyPlaying else { return }
                await viewmodel.loadArtwork(for: trackID)
            }
            .task(id: viewmodel.userDefaultStorage.hasOnboarded) {
                guard viewmodel.userDefaultStorage.hasOnboarded, !viewmodel.isFirstFetch else {
                    return
                }
                do {
                    try await viewmodel.refreshLyrics()
                } catch {
                    print("Couldn't refresh lyrics after player authorization changed: \(error)")
                }
            }
            .onChange(of: viewmodel.showLyrics) {
                viewmodel.toggleLyrics()
            }
            .onChange(of: viewmodel.userDefaultStorage.karaoke) {
                if viewmodel.shouldUpdateLyrics, viewmodel.isPlaying, !viewmodel.currentlyPlayingLyrics.isEmpty {
                    viewmodel.startLyricUpdater()
                } else {
                    viewmodel.stopLyricUpdater()
                }
            }
            .floatingPanel(isPresented: $viewmodel.isKaraokeWindowPresented) {
                KaraokeView()
                    .animation(.easeIn(duration: 0.2))
                    .environment(viewmodel)
            }
            .onAppear {
                viewmodel.onAppear(openWindow)
            }
            .onReceive(DistributedNotificationCenter.default().publisher(for: Notification.Name(rawValue:  "com.apple.Music.playerInfo"))) { notification in
                viewmodel.appleMusicPlaybackDidChange(notification)
            }
            .onReceive(DistributedNotificationCenter.default().publisher(for: Notification.Name(rawValue:  "com.spotify.client.PlaybackStateChanged"))) { notification in
                viewmodel.spotifyPlaybackDidChange(notification)
            }
            .translationTask(viewmodel.translationSessionConfig) { session in
                await viewmodel.translationTask(session)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                viewmodel.saveKaraokeFontOnTermination()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                viewmodel.refreshPlayerAuthorization()
            }
            .onChange(of: viewmodel.translationSourceLanguage) {
                // don't call reloadTranslationConfigIfTranslating(), that invalidates when config is the same
                if viewmodel.userDefaultStorage.translate {
                    viewmodel.translationSessionConfig = TranslationSession.Configuration(source: viewmodel.translationSourceLanguage, target: viewmodel.userLocaleLanguage)
                }
            }
            .onChange(of: viewmodel.userLocaleLanguage) {
                let _ = viewmodel.reloadTranslationConfigIfTranslating()
            }
            .onChange(of: viewmodel.userDefaultStorage.chinesePreference) {
                viewmodel.chinesePreferenceDidChange()
            }
            .onChange(of: viewmodel.userDefaultStorage.romanize) {
                viewmodel.romanizeDidChange()
            }
//            .onChange(of: viewmodel.userDefaultStorage.romanizeMetadata) {
//                if viewmodel.userDefaultStorage.romanizeMetadata {
//                    viewmodel.romanizeMetadata()
//                }
//            }
            .onChange(of: viewmodel.userDefaultStorage.translate) {
                if !viewmodel.reloadTranslationConfigIfTranslating() {
                    viewmodel.translatedLyric = []
                }
            }
            .onChange(of: viewmodel.currentPlayer) {
                viewmodel.syncAppleMusicArtworkListener()
                viewmodel.refreshPlayerAuthorization()
            }
            .onChange(of: viewmodel.fullscreen) {
                if viewmodel.fullscreen {
                    openWindow(id: "fullscreen")
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
            }
            .onChange(of: viewmodel.userDefaultStorage.hasOnboarded) {
                if viewmodel.userDefaultStorage.hasOnboarded {
                    viewmodel.didOnboard()
                } else {
                    viewmodel.stopLyricUpdater()
                }
            }
            .onChange(of: viewmodel.userDefaultStorage.translate) {
                viewmodel.openTranslationHelpOnFirstRun(openURL)
            }
            .onChange(of: viewmodel.userDefaultStorage.cookie) {
                viewmodel.spotifyLyricProvider.accessToken = nil
            }
            .onChange(of: viewmodel.isPlaying) {
                if viewmodel.isPlaying, viewmodel.shouldUpdateLyrics, viewmodel.userDefaultStorage.hasOnboarded {
                    if !viewmodel.currentlyPlayingLyrics.isEmpty  {
                        print("timer started for spotify change, lyrics not nil")
                        viewmodel.startLyricUpdater()
                    }
                } else {
                    viewmodel.stopLyricUpdater()
                }
            }
            .task(id: viewmodel.currentlyPlayingAppleMusicPersistentID) {
                if viewmodel.currentlyPlayingAppleMusicPersistentID != nil {
                    print("Apple Music: calling Starter on new persistent ID")
                    await viewmodel.appleMusicStarter()
                }
            }
            .onChange(of: viewmodel.currentlyPlaying) {
                print("song change")
                Task {
                    await viewmodel.onCurrentlyPlayingIDChange()
                }
            }
        }
        .menuBarExtraAccess(isPresented: $viewmodel.isMenuBarWidgetPresented)
        .menuBarExtraStyle(.window)
        Window("LyricChiller: Fullscreen", id: "fullscreen") {
            FullscreenView()
                .windowFullScreenBehavior(.enabled)
                .preferredColorScheme(.dark)
                .environment(viewmodel)
                .onAppear {
                    // Block "Esc" button
                    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (aEvent) -> NSEvent? in
                            if aEvent.keyCode == 53 { // if esc pressed
                                return nil
                            }
                            return aEvent
                        }
                    Task { @MainActor in
                        let window = NSApp.windows.first {$0.identifier?.rawValue == "fullscreen"}
                        window?.collectionBehavior = .fullScreenPrimary
                        if window?.styleMask.rawValue != 49167 {
                            window?.toggleFullScreen(true)
                        }
                    }
                }
                .onDisappear {
                    NSApp.setActivationPolicy(.accessory)
                    viewmodel.fullscreen = false
                }
        }
        .defaultSize(width: NSScreen.mainWidth, height: NSScreen.mainHeight)
        Window("LyricChiller: Searching for \(viewmodel.currentlyPlayingName ?? "-") by \(viewmodel.currentlyPlayingArtist ?? "-")", id: "search") {
            SearchWindow().frame(minWidth: 700, maxWidth: 700, minHeight: 500, maxHeight: 500, alignment: .center)
                .environment(viewmodel)
                .preferredColorScheme(.dark)
                .onAppear {
                    NSApp.setActivationPolicy(.regular)
                }
                .onDisappear {
                    if !viewmodel.fullscreen {
                        NSApp.setActivationPolicy(.accessory)
                    }
                }
        }
        .windowResizability(.contentSize)
    }
}

@MainActor
final class LyricChillerAppDelegate: NSObject, NSApplicationDelegate {
    private let initialSettingsPresentedKey = "hasPresentedInitialSettings"

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !UserDefaults.standard.bool(forKey: initialSettingsPresentedKey) else { return }
        UserDefaults.standard.set(true, forKey: initialSettingsPresentedKey)

        DispatchQueue.main.async {
            LyricChillerSettingsWindowController.shared.open(viewModel: .shared, tab: .playback)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        guard !ViewModel.shared.userDefaultStorage.showMenubarIcon else { return false }
        LyricChillerSettingsWindowController.shared.open(viewModel: .shared)
        return true
    }
}


extension String {
  // https://gist.github.com/budidino/8585eecd55fd4284afaaef762450f98e
    @MainActor
    func trunc(length: Int? = nil, trailing: String = "…") -> String {
        let length = length ?? ViewModel.shared.userDefaultStorage.truncationLength
        return (self.count > length) ? self.prefix(length) + trailing : self
    }
}

