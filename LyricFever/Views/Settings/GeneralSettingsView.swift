import LaunchAtLogin
import SwiftUI

struct LyricChillGeneralSettingsView: View {
    @Environment(ViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ModularSettingsSection("General") {
                ModularSettingsRow("Launch at login", keywords: ["startup", "launch"]) {
                    LaunchAtLogin.Toggle("")
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }

            ModularSettingsSection("Updates") {
                ModularSettingsRow(
                    "Check for updates",
                    helperText: "Check whether a newer LyricChill version is available.",
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
