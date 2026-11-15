import LaunchAtLogin
import SwiftUI

struct LyricChillerGeneralSettingsView: View {
    @Environment(ViewModel.self) private var viewModel
    @AppStorage("truncationLength") private var truncationLength = 40

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(alignment: .leading, spacing: 20) {
            ModularSettingsSection("Menu Bar") {
                ModularSettingsRow(
                    "Show menu bar icon",
                    helperText: "Show the LyricChiller menu bar icon and controls.",
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
                    "Check for updates",
                    helperText: "Check whether a newer LyricChiller version is available.",
                    keywords: ["update", "version"]
                ) {
                    Button("Check Now") {
                        viewModel.updaterService.updaterController.checkForUpdates(nil)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
