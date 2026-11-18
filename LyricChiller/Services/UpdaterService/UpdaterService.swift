//
//  UpdaterService.swift
//  LyricChiller
//

import Foundation
import Sparkle

@MainActor
final class UpdaterService: NSObject, SPUStandardUserDriverDelegate, SPUUpdaterDelegate {
    nonisolated static let releaseChannel = "lyricchiller"
    nonisolated static let appcastTargetBundleIdentifierKey = "lyricchiller:targetBundleIdentifier"

    var updaterController: SPUStandardUpdaterController!

    override init() {
        super.init()
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: self,
            userDriverDelegate: self
        )
    }

    nonisolated func allowedChannels(for updater: SPUUpdater) -> Set<String> {
        [Self.releaseChannel]
    }

    nonisolated func bestValidUpdate(in appcast: SUAppcast, for updater: SPUUpdater) -> SUAppcastItem? {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return SUAppcastItem.empty()
        }

        let eligibleItems = appcast.items.filter { item in
            item.propertiesDictionary[Self.appcastTargetBundleIdentifierKey] as? String == bundleIdentifier
        }

        guard !eligibleItems.isEmpty else {
            return SUAppcastItem.empty()
        }

        let comparator = SUStandardVersionComparator.default
        return eligibleItems.max { left, right in
            comparator.compareVersion(left.versionString, toVersion: right.versionString) == .orderedAscending
        }
    }

    nonisolated var supportsGentleScheduledUpdateReminders: Bool {
        true
    }

    nonisolated func standardUserDriverShouldHandleShowingScheduledUpdate(
        _ update: SUAppcastItem,
        andInImmediateFocus immediateFocus: Bool
    ) -> Bool {
        true
    }

    @MainActor
    var urgentUpdateExists: Bool {
        get async {
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let url = URL(string: "https://raw.githubusercontent.com/aviwad/LyricFeverHomepage/master/urgentUpdateVersion.md") {
                let request = URLRequest(url: url)
                let urlResponseAndData = try? await URLSession(configuration: .ephemeral).data(for: request)
                if let urlResponseAndData,
                   let internetUrgentVersionString = String(bytes: urlResponseAndData.0, encoding: .utf8),
                   let internetUrgentVersion = Double(internetUrgentVersionString),
                   let currentVersion = Double(version) {
                    print("current version is \(currentVersion), internet urgent version is \(internetUrgentVersion)")
                    if currentVersion < internetUrgentVersion {
                        print("NOT EQUAL")
                        return true
                    } else {
                        print("EQUAL")
                        return false
                    }
                }
            }
            return false
        }
    }
}
