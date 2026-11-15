import AppKit
import SwiftUI

@MainActor
final class LyricChillerSettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = LyricChillerSettingsWindowController()

    private var windowController: NSWindowController?
    private var onboardingWindowController: NSWindowController?

    func open(viewModel: ViewModel, tab: LyricChillerSettingsTab = .general) {
        if let windowController, let window = windowController.window {
            configure(window)
            windowController.showWindow(nil)
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            NotificationCenter.default.post(name: .lyricChillSettingsTabRequested, object: tab)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 750, height: 550),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.identifier = NSUserInterfaceItemIdentifier("LyricChillerSettingsWindow")
        window.title = "LyricChiller Settings"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.center()
        window.minSize = NSSize(width: 750, height: 550)
        configure(window)
        window.level = .normal
        window.contentViewController = LyricChillerSettingsHostingController(
            viewModel: viewModel,
            initialTab: tab
        )

        let controller = NSWindowController(window: window)
        controller.window?.delegate = self
        windowController = controller

        controller.showWindow(nil)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        windowController = nil
        if !ViewModel.shared.fullscreen {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    func showSetupOnboarding() {
        if let onboardingWindow = onboardingWindowController?.window, onboardingWindow.isVisible {
            NSApp.activate(ignoringOtherApps: true)
            onboardingWindow.makeKeyAndOrderFront(nil)
            return
        }

        guard let parentWindow = windowController?.window else { return }

        let onboardingView = LyricChillerSetupOnboardingView { [weak self] in
            self?.finishSetupOnboarding()
        }
        .environment(ViewModel.shared)

        let hostingController = NSHostingController(rootView: onboardingView)
        let onboardingWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 750, height: 550),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        onboardingWindow.titlebarAppearsTransparent = true
        onboardingWindow.titleVisibility = .hidden
        onboardingWindow.isMovableByWindowBackground = true
        onboardingWindow.contentViewController = hostingController

        let onboardingController = NSWindowController(window: onboardingWindow)
        onboardingWindowController = onboardingController

        parentWindow.beginSheet(onboardingWindow) { [weak self] _ in
            UserDefaults.standard.set(true, forKey: "hasCompletedSetupOnboarding")
            self?.onboardingWindowController = nil
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    private func finishSetupOnboarding() {
        ViewModel.shared.refreshPlayerAuthorization()
        UserDefaults.standard.set(true, forKey: "hasCompletedSetupOnboarding")

        guard let onboardingWindow = onboardingWindowController?.window,
              let parentWindow = onboardingWindow.sheetParent else {
            onboardingWindowController?.close()
            onboardingWindowController = nil
            return
        }

        parentWindow.endSheet(onboardingWindow)
    }

    private func configure(_ window: NSWindow) {
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .participatesInCycle,
        ]
    }
}

private final class LyricChillerSettingsHostingController: NSHostingController<AnyView> {
    init(viewModel: ViewModel, initialTab: LyricChillerSettingsTab) {
        let rootView = LyricChillerSettingsView(initialTab: initialTab)
            .environment(viewModel)
        super.init(rootView: AnyView(rootView))
    }

    @MainActor required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = NSSize(width: 750, height: 550)
    }
}
