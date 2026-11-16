import AppKit
import KeyboardShortcuts
import SwiftUI

struct GlobalKeyboardShortcutsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(LyricChillerShortcutGroup.allCases) { group in
                ModularSettingsSection(group.title) {
                    ForEach(group.shortcuts) { shortcut in
                        if shortcut != group.shortcuts.first {
                            Divider()
                        }
                        LyricChillerShortcutRow(shortcut: shortcut)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private enum LyricChillerShortcutGroup: String, CaseIterable, Identifiable {
    case windows
    case menuBar
    case lyrics

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .windows: "Windows"
        case .menuBar: "Menu Bar"
        case .lyrics: "Lyrics"
        }
    }

    var shortcuts: [LyricChillerShortcut] {
        switch self {
        case .windows: [.karaoke, .fullscreen]
        case .menuBar: [.menuBarWidget, .lyrics]
        case .lyrics: [.translate, .romanize]
        }
    }
}

private enum LyricChillerShortcut: String, CaseIterable, Identifiable, Equatable {
    case karaoke
    case lyrics
    case menuBarWidget
    case translate
    case romanize
    case fullscreen

    var id: String { rawValue }

    var name: KeyboardShortcuts.Name { .init(rawValue) }

    var title: LocalizedStringResource {
        switch self {
        case .karaoke: "Toggle karaoke window"
        case .lyrics: "Toggle menu bar lyrics"
        case .menuBarWidget: "Open menu bar controls"
        case .translate: "Toggle translations"
        case .romanize: "Toggle romanization"
        case .fullscreen: "Open fullscreen lyrics"
        }
    }

    var keywords: [String] {
        switch self {
        case .karaoke: ["lyrics", "overlay"]
        case .lyrics: ["show", "hide"]
        case .menuBarWidget: ["menu", "widget", "show", "open"]
        case .translate: ["translation"]
        case .romanize: ["romanization"]
        case .fullscreen: ["fullscreen", "karaoke"]
        }
    }
}

private struct LyricChillerShortcutRow: View {
    let shortcut: LyricChillerShortcut

    @State private var isListening = false
    @State private var shortcutRevision = 0

    private var shortcutText: String {
        let _ = shortcutRevision
        if isListening {
            return String(localized: "Press new shortcut…")
        }
        return KeyboardShortcuts.getShortcut(for: shortcut.name)?.description
            ?? String(localized: "Unassigned")
    }

    private var canReset: Bool {
        KeyboardShortcuts.getShortcut(for: shortcut.name) != nil
    }

    var body: some View {
        ModularSettingsShortcutRow(
            shortcut.title,
            keywords: shortcut.keywords,
            shortcutText: shortcutText,
            isListening: isListening,
            canReset: canReset,
            onListen: { isListening = true },
            onReset: {
                KeyboardShortcuts.reset(shortcut.name)
                shortcutRevision += 1
            }
        )
        .background {
            KeyboardShortcutRecorderBridge(
                name: shortcut.name,
                isListening: $isListening,
                onShortcutChange: { shortcutRevision += 1 }
            )
            .frame(width: 130, height: 24)
            .opacity(0.001)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

private struct KeyboardShortcutRecorderBridge: NSViewRepresentable {
    let name: KeyboardShortcuts.Name
    @Binding var isListening: Bool
    let onShortcutChange: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(isListening: $isListening)
    }

    func makeNSView(context: Context) -> KeyboardShortcuts.RecorderCocoa {
        let recorder = KeyboardShortcuts.RecorderCocoa(for: name) { _ in
            DispatchQueue.main.async {
                context.coordinator.isListening.wrappedValue = false
                onShortcutChange()
            }
        }
        recorder.focusRingType = .none
        return recorder
    }

    func updateNSView(_ recorder: KeyboardShortcuts.RecorderCocoa, context: Context) {
        context.coordinator.isListening = $isListening

        if isListening {
            DispatchQueue.main.async {
                guard context.coordinator.isListening.wrappedValue,
                      let window = recorder.window else { return }
                if window.firstResponder !== recorder {
                    window.makeFirstResponder(recorder)
                }
            }
        } else if recorder.window?.firstResponder === recorder {
            recorder.window?.makeFirstResponder(nil)
        }
    }

    static func dismantleNSView(_ recorder: KeyboardShortcuts.RecorderCocoa, coordinator: Coordinator) {
        coordinator.stopObserving()
    }

    @MainActor
    final class Coordinator {
        var isListening: Binding<Bool>
        private var activeStatusObserver: NSObjectProtocol?

        init(isListening: Binding<Bool>) {
            self.isListening = isListening
            activeStatusObserver = NotificationCenter.default.addObserver(
                forName: Notification.Name("KeyboardShortcuts_recorderActiveStatusDidChange"),
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let isActive = notification.userInfo?["isActive"] as? Bool,
                      !isActive else { return }
                Task { @MainActor [weak self] in
                    guard let self, self.isListening.wrappedValue else { return }
                    self.isListening.wrappedValue = false
                }
            }
        }

        func stopObserving() {
            if let activeStatusObserver {
                NotificationCenter.default.removeObserver(activeStatusObserver)
                self.activeStatusObserver = nil
            }
        }
    }
}
