import AppKit
import LaunchAtLogin
import SwiftUI

struct LyricChillGeneralSettingsView: View {
    @Environment(ViewModel.self) private var viewModel
    @State private var showingSpotifyConnection = false
    @State private var playerAccessRevision = 0
    @AppStorage("spotifyOrAppleMusic") private var spotifyOrAppleMusic = false
    @AppStorage("truncationLength") private var truncationLength = 40

    var body: some View {
        @Bindable var viewModel = viewModel
        let _ = playerAccessRevision
        let playerIsAuthorized = viewModel.currentPlayerInstance.isAuthorized
        let playerIsRunning = viewModel.currentPlayerInstance.isRunning

        VStack(alignment: .leading, spacing: 20) {
            ModularSettingsSection("Playback") {
                ModularSettingsRow(
                    "Music app",
                    helperText: "Choose the app LyricChill reads playback information from.",
                    keywords: ["Spotify", "Apple Music", "player"]
                ) {
                    if #available(macOS 26.0, *) {
                        MusicAppPicker(selection: $spotifyOrAppleMusic)
                            .fixedSize(horizontal: true, vertical: false)
                            .accessibilityLabel("Music app")
                    } else {
                        Picker("Music app", selection: $spotifyOrAppleMusic) {
                            Text("Spotify").tag(false)
                            Text("Apple Music").tag(true)
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .controlSize(.large)
                    }
                }

                Divider()

                ModularSettingsRow(
                    "Player access",
                    helperText: "LyricChill needs permission to read the selected music app's playback state.",
                    warningText: playerIsRunning && !playerIsAuthorized
                        ? "Open the selected player and grant LyricChill access in Automation Settings."
                        : nil,
                    keywords: ["permission", "authorization"]
                ) {
                    HStack(spacing: 10) {
                        if playerIsRunning {
                            ModularSettingsPermissionStatusIcon(isGranted: playerIsAuthorized)
                        } else {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.secondary)
                                .accessibilityLabel("Player not running")
                        }
                        Text(playerIsAuthorized ? "Ready" : playerIsRunning ? "Setup required" : "Player not running")
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        Button("Open Setup") {
                            _ = viewModel.currentPlayerInstance.isAuthorized
                            guard let settingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") else {
                                return
                            }
                            NSWorkspace.shared.open(settingsURL)
                        }
                    }
                }
            }

            ModularSettingsSection("Playback timing") {
                if viewModel.currentPlayer == .spotify {
                    ModularSettingsRow(
                        "Spotify Connect Audio Delay",
                        helperText: "Adjust lyric timing to match Spotify Connect playback.",
                        keywords: ["Spotify", "Connect", "offset", "timing"]
                    ) {
                        Toggle("Spotify Connect Audio Delay", isOn: $viewModel.spotifyConnectDelay)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }

                    if viewModel.spotifyConnectDelay {
                        Divider()

                        ModularSettingsSliderRow(
                            "Spotify Delay",
                            helperText: "Offset applied to Spotify Connect playback.",
                            keywords: ["Spotify", "Connect", "offset", "milliseconds"],
                            value: Binding(
                                get: { Double(viewModel.userDefaultStorage.spotifyConnectDelayCount) },
                                set: { newValue in
                                    viewModel.userDefaultStorage.spotifyConnectDelayCount = Int((newValue / 100).rounded() * 100)
                                }
                            ),
                            range: 300.0...3000.0,
                            defaultValue: 400.0,
                            step: 100.0,
                            valueString: { "\(($0 / 1000).formatted(.number.precision(.fractionLength(1)))) s" }
                        )
                    }
                }

                if viewModel.currentPlayer == .spotify {
                    Divider()
                }

                ModularSettingsRow(
                    "AirPlay Audio Delay",
                    helperText: "Compensate for AirPlay playback latency when lyrics appear late.",
                    keywords: ["AirPlay", "offset", "timing"]
                ) {
                    Toggle("AirPlay Audio Delay", isOn: $viewModel.airplayDelay)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }

            ModularSettingsSection("Lyrics") {
                ModularSettingsRow(
                    "Primary lyric source",
                    helperText: "LyricChill tries this source first, then falls back to other available providers.",
                    keywords: ["LRCLIB", "Spotify", "NetEase", "provider"]
                ) {
                    Picker("", selection: $viewModel.userDefaultStorage.lyricSourcePreference) {
                        Text("LRCLIB").tag("LRCLIB")
                        Text("Spotify").tag("Spotify")
                        Text("NetEase").tag("NetEase")
                    }
                    .labelsHidden()
                }

                Divider()

                ModularSettingsRow(
                    "Spotify lyrics",
                    helperText: "Spotify login is optional. LRCLIB and NetEase work without a Spotify account.",
                    keywords: ["login", "account", "cookie", "connect"]
                ) {
                    HStack(spacing: 10) {
                        Text(viewModel.userDefaultStorage.cookie.isEmpty ? "Not connected" : "Connected")
                            .foregroundStyle(.secondary)
                        Button("Manage") {
                            showingSpotifyConnection = true
                        }
                    }
                }

            }

            ModularSettingsSection("Menu Bar") {
                ModularSettingsRow(
                    "Show song details in menu bar",
                    helperText: "Show the current song title and artist in the menu bar.",
                    keywords: ["title", "artist", "display"]
                ) {
                    Toggle("Show song details in menu bar", isOn: $viewModel.userDefaultStorage.showSongDetailsInMenubar)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                Divider()

                ModularSettingsRow(
                    "Menu bar lyric length",
                    helperText: "Choose the maximum number of characters shown in the menu bar.",
                    keywords: ["truncation", "characters", "display"]
                ) {
                    Picker("", selection: $truncationLength) {
                        ForEach([30, 40, 50, 60], id: \.self) { length in
                            Text("\(length) characters").tag(length)
                        }
                    }
                    .labelsHidden()
                }
            }

            ModularSettingsSection("System") {
                ModularSettingsRow("Launch at login", keywords: ["startup", "launch"]) {
                    LaunchAtLogin.Toggle("")
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            playerAccessRevision += 1
        }
        .sheet(isPresented: $showingSpotifyConnection) {
            NavigationStack {
                ApiView(onComplete: { showingSpotifyConnection = false })
            }
            .frame(minWidth: 720, minHeight: 560)
            .preferredColorScheme(.dark)
        }
    }
}

@available(macOS 26.0, *)
private struct MusicAppPicker: NSViewRepresentable {
    @Binding var selection: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    func makeNSView(context: Context) -> NSSegmentedControl {
        let control = NSSegmentedControl()
        control.segmentCount = 2
        control.trackingMode = .selectOne
        control.segmentStyle = .automatic
        control.controlSize = .regular
        control.borderShape = .capsule
        control.segmentDistribution = .fit

        if #available(macOS 27.0, *) {
            control.role = .tabs
        }

        control.setLabel(String(localized: "Spotify"), forSegment: 0)
        control.setLabel(String(localized: "Apple Music"), forSegment: 1)
        control.target = context.coordinator
        control.action = #selector(Coordinator.selectionChanged(_:))
        control.selectedSegment = selection ? 1 : 0
        return control
    }

    func updateNSView(_ control: NSSegmentedControl, context: Context) {
        context.coordinator.selection = $selection
        control.selectedSegment = selection ? 1 : 0
    }

    @MainActor
    final class Coordinator: NSObject {
        var selection: Binding<Bool>

        init(selection: Binding<Bool>) {
            self.selection = selection
        }

        @objc func selectionChanged(_ sender: NSSegmentedControl) {
            guard (0..<2).contains(sender.selectedSegment) else { return }
            selection.wrappedValue = sender.selectedSegment == 1
        }
    }
}
