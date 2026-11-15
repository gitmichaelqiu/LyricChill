import AppKit
import SwiftUI

struct MusicAppPicker: View {
    @Binding var selection: Bool

    var body: some View {
        if #available(macOS 26.0, *) {
            MusicAppTabControl(selection: $selection)
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityLabel("Music app")
        } else {
            Picker("Music app", selection: $selection) {
                Text("Spotify").tag(false)
                Text("Apple Music").tag(true)
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .controlSize(.large)
        }
    }
}

@available(macOS 26.0, *)
private struct MusicAppTabControl: NSViewRepresentable {
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
