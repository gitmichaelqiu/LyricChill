import SwiftUI

struct LyricChillMenuBarSettingsView: View {
    @Environment(ViewModel.self) private var viewModel
    @AppStorage("truncationLength") private var truncationLength = 40

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(alignment: .leading, spacing: 20) {
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
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
