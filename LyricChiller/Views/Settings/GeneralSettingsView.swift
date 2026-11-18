import LaunchAtLogin
import SwiftUI

struct LyricChillerGeneralSettingsView: View {
    @Environment(ViewModel.self) private var viewModel
    @AppStorage("truncationLength") private var truncationLength = 40
    @State private var automaticallyChecksForUpdates = true
    @State private var automaticallyDownloadsUpdates = true

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(alignment: .leading, spacing: 20) {
            ModularSettingsSection("Menu Bar") {
                ModularSettingsRow(
                    "Show menu bar icon",
                    keywords: ["icon", "status item", "controls"]
                ) {
                    Toggle(
                        "Show menu bar icon",
                        isOn: Binding(
                            get: { viewModel.userDefaultStorage.showMenubarIcon },
                            set: { isVisible in
                                withModularSettingsAnimation {
                                    viewModel.userDefaultStorage.showMenubarIcon = isVisible
                                }
                            }
                        )
                    )
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                if viewModel.userDefaultStorage.showMenubarIcon {
                    Group {
                        Divider()

                        ModularSettingsRow(
                            "Show song details in menu bar",
                            helperText: "When menu bar lyrics are hidden or unavailable, show the current song title and artist.",
                            keywords: ["title", "artist", "display"]
                        ) {
                            Toggle(
                                "Show song details in menu bar",
                                isOn: Binding(
                                    get: { viewModel.userDefaultStorage.showSongDetailsInMenubar },
                                    set: { showDetails in
                                        withModularSettingsAnimation {
                                            viewModel.userDefaultStorage.showSongDetailsInMenubar = showDetails
                                        }
                                    }
                                )
                            )
                            .labelsHidden()
                            .toggleStyle(.switch)
                        }

                        if viewModel.userDefaultStorage.showSongDetailsInMenubar {
                            Group {
                                Divider()

                                ModularSettingsRow(
                                    "Menu bar lyric length",
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
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            ModularSettingsSection("System") {
                ModularSettingsRow("Launch at login", keywords: ["startup", "launch"]) {
                    LaunchAtLogin.Toggle("")
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }

            ModularSettingsSection("Updates") {
                ModularSettingsRow(
                    "Automatically check for updates",
                    keywords: ["update", "automatic", "background"]
                ) {
                    Toggle(
                        "Automatically check for updates",
                        isOn: Binding(
                            get: { automaticallyChecksForUpdates },
                            set: { value in
                                withModularSettingsAnimation {
                                    automaticallyChecksForUpdates = value
                                }
                            }
                        )
                    )
                    .labelsHidden()
                    .toggleStyle(.switch)
                }

                if automaticallyChecksForUpdates {
                    Group {
                        Divider()

                        ModularSettingsRow(
                            "Automatically download updates",
                            keywords: ["update", "download", "automatic"]
                        ) {
                            Toggle(
                                "Automatically download updates",
                                isOn: Binding(
                                    get: { automaticallyDownloadsUpdates },
                                    set: { value in
                                        withModularSettingsAnimation {
                                            automaticallyDownloadsUpdates = value
                                        }
                                    }
                                )
                            )
                            .labelsHidden()
                            .toggleStyle(.switch)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Divider()

                ModularSettingsRow(
                    "Check for updates",
                    keywords: ["update", "version", "manual"]
                ) {
                    Button("Check Now") {
                        viewModel.updaterService.updaterController.checkForUpdates(nil)
                    }
                }
            }

            ModularSettingsSection("Advanced") {
                ModularSettingsRow(
                    "Review onboarding",
                    keywords: ["setup", "welcome", "walkthrough"]
                ) {
                    Button("Review") {
                        LyricChillerSettingsWindowController.shared.showSetupOnboarding()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .onAppear {
            let updater = viewModel.updaterService.updaterController.updater
            automaticallyChecksForUpdates = updater.automaticallyChecksForUpdates
            automaticallyDownloadsUpdates = updater.automaticallyDownloadsUpdates
        }
        .onChange(of: automaticallyChecksForUpdates) { _, value in
            viewModel.updaterService.updaterController.updater.automaticallyChecksForUpdates = value
        }
        .onChange(of: automaticallyDownloadsUpdates) { _, value in
            viewModel.updaterService.updaterController.updater.automaticallyDownloadsUpdates = value
        }
    }
}
