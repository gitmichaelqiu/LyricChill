import AppKit
import SwiftUI

struct LyricChillerSetupOnboardingView: View {
    @Environment(ViewModel.self) private var viewModel
    @AppStorage("spotifyOrAppleMusic") private var usesAppleMusic = false
    @State private var currentPage = 0
    @State private var movingForward = true
    @State private var playerAccessRevision = 0

    let onFinish: () -> Void

    private let pageCount = 3

    private var playerIsAuthorized: Bool {
        _ = playerAccessRevision
        return viewModel.currentPlayerInstance.isAuthorized
    }

    private var playerIsRunning: Bool {
        _ = playerAccessRevision
        return viewModel.currentPlayerInstance.isRunning
    }

    private var selectedMusicAppName: String {
        usesAppleMusic ? String(localized: "Apple Music") : String(localized: "Spotify")
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 0) {
            ZStack {
                pageContent
                    .id(currentPage)
                    .transition(pageTransition)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            navigationBar
        }
        .frame(width: 750, height: 550)
        .background(Color(nsColor: .windowBackgroundColor))
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            playerAccessRevision += 1
            viewModel.refreshPlayerAuthorization()
        }
    }

    @ViewBuilder
    private var pageContent: some View {
        switch currentPage {
        case 0:
            welcomePage
        case 1:
            playbackPage
        default:
            lyricsPage
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 18) {
            if let icon = NSApplication.shared.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
            }

            Text("Welcome to LyricChiller")
                .font(.system(size: 30, weight: .bold, design: .rounded))

            Text("A lyrics companion for Spotify and Apple Music.")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("A couple of quick steps will connect your player and choose where LyricChiller looks for lyrics.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)
        }
        .padding(32)
    }

    private var playbackPage: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Choose your music app")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("LyricChiller uses this app to find the song you’re listening to and show its lyrics.")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Music app")
                    .font(.headline)
                Spacer()
                MusicAppPicker(selection: $usesAppleMusic)
            }
            .padding(12)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 12) {
                Image(systemName: playerIsAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(playerIsAuthorized ? Color.green : Color.orange)
                    .font(.title2)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    playerAccessTitle
                        .font(.headline)
                    playerAccessDescription
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if playerIsRunning && !playerIsAuthorized {
                    Button("Open System Settings") {
                        _ = viewModel.currentPlayerInstance.isAuthorized
                        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") else { return }
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            .padding(16)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

            if playerIsRunning && !playerIsAuthorized {
                Text("If macOS asks, click Allow. If you previously denied access, open System Settings → Privacy & Security → Automation and enable \(selectedMusicAppName) for LyricChiller.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("You can change the music app later in Settings → Playback.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 56)
    }

    @ViewBuilder
    private var playerAccessTitle: some View {
        if playerIsAuthorized {
            Text("You’re all set")
        } else if playerIsRunning {
            Text("Allow LyricChiller to read playback")
        } else {
            Text("Open \(selectedMusicAppName) and start a song")
        }
    }

    @ViewBuilder
    private var playerAccessDescription: some View {
        if playerIsAuthorized {
            Text("LyricChiller can read the song title, artist, and playback position.")
        } else if playerIsRunning {
            Text("LyricChiller needs permission to read the current song and playback position.")
        } else {
            Text("When macOS asks to let LyricChiller read playback, click Allow.")
        }
    }

    private var lyricsPage: some View {
        @Bindable var viewModel = viewModel

        return VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Choose a lyric source")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Select the provider LyricChiller should try first.")
                    .foregroundStyle(.secondary)
            }

            Picker("Primary lyric source", selection: $viewModel.userDefaultStorage.lyricSourcePreference) {
                Text("LRCLIB").tag("LRCLIB")
                Text("Spotify").tag("Spotify")
                Text("NetEase").tag("NetEase")
            }
            .frame(maxWidth: 360)

            VStack(alignment: .leading, spacing: 8) {
                Label("LRCLIB and NetEase work without an account.", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.secondary)
                Label("Spotify lyrics login is optional.", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .font(.callout)
            .padding(16)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

            Text("You can change lyric sources or connect Spotify later in Settings → Lyrics.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 56)
    }

    private var navigationBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(0..<pageCount, id: \.self) { index in
                    Capsule()
                        .fill(currentPage == index ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: currentPage == index ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                }
            }

            Spacer()

            if currentPage < pageCount - 1 {
                Button("Skip") {
                    onFinish()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundStyle(.secondary)
            }

            if currentPage > 0 {
                Button("Back") {
                    movingForward = false
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage -= 1
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundStyle(.secondary)
            }

            Button {
                guard currentPage < pageCount - 1 else {
                    onFinish()
                    return
                }
                movingForward = true
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPage += 1
                }
            } label: {
                Text(currentPage == pageCount - 1 ? "Finish Setup" : "Next")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
    }

    private var pageTransition: AnyTransition {
        if movingForward {
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }

        return .asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
    }
}
