import AppKit
import SwiftUI

struct LyricChillerPlaybackSettingsView: View {
    @Environment(ViewModel.self) private var viewModel
    @State private var playerAccessRevision = 0
    @AppStorage("spotifyOrAppleMusic") private var spotifyOrAppleMusic = false

    var body: some View {
        @Bindable var viewModel = viewModel
        let _ = playerAccessRevision
        let playerIsAuthorized = viewModel.currentPlayerInstance.isAuthorized
        let playerIsRunning = viewModel.currentPlayerInstance.isRunning

        VStack(alignment: .leading, spacing: 20) {
            ModularSettingsSection("Playback") {
                ModularSettingsRow(
                    "Music app",
                    helperText: "Choose the app LyricChiller reads playback information from.",
                    keywords: ["Spotify", "Apple Music", "player"]
                ) {
                    MusicAppPicker(selection: $spotifyOrAppleMusic)
                }

                Divider()

                ModularSettingsRow(
                    "Player access",
                    helperText: "To show lyrics, LyricChiller needs permission to read the current song from the selected music app.",
                    warningText: playerIsRunning && !playerIsAuthorized
                        ? "If access was denied, open System Settings → Privacy & Security → Automation and enable the selected music app for LyricChiller."
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

                        Text(playerIsAuthorized ? "Ready" : playerIsRunning ? "Permission needed" : "Player not running")
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)

                        if playerIsRunning && !playerIsAuthorized {
                            Button("Open System Settings") {
                                _ = viewModel.currentPlayerInstance.isAuthorized
                                guard let settingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") else {
                                    return
                                }
                                NSWorkspace.shared.open(settingsURL)
                            }
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
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            playerAccessRevision += 1
            viewModel.refreshPlayerAuthorization()
        }
    }
}
