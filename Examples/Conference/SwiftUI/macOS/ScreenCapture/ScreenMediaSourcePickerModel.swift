import PexipMedia
import Combine
import AppKit
import PexipScreenCapture

final class ScreenMediaSourcePickerModel: ObservableObject {
    @Published private(set) var displays = [Display]()
    @Published private(set) var windows = [Window]()
    @Published private(set) var showingErrorMessage = false
    @Published var selectedVideoSource: ScreenMediaSource?

    private let enumerator: ScreenMediaSourceEnumerator
    private let onShare: (ScreenMediaSource) -> Void
    private let onCancel: () -> Void

    // MARK: - Init

    init(
        enumerator: ScreenMediaSourceEnumerator,
        onShare: @escaping (ScreenMediaSource) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.enumerator = enumerator
        self.onShare = onShare
        self.onCancel = onCancel

        Task {
            await loadDisplays()
            await loadWindows()
        }
    }

    // MARK: - Actions

    @MainActor
    func loadDisplays() async {
        showingErrorMessage = false

        do {
            displays = try await enumerator.getShareableDisplays()
        } catch {
            showingErrorMessage = true
            debugPrint(error)
        }

        selectVideoSourceIfNeeded()
    }

    @MainActor
    func loadWindows() async {
        showingErrorMessage = false

        do {
            windows = try await enumerator.getShareableWindows()
        } catch {
            showingErrorMessage = true
            debugPrint(error)
        }

        selectVideoSourceIfNeeded()
    }

    func cancel() {
        onCancel()
    }

    func share() {
        if let selectedVideoSource = selectedVideoSource {
            onShare(selectedVideoSource)
        }
    }

    func openSettings() {
        if let url = enumerator.permissionSettingsURL {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Private

    private func selectVideoSourceIfNeeded() {
        if let selectedVideoSource = selectedVideoSource {
            switch selectedVideoSource {
            case .display(let display):
                if displays.contains(where: { $0.displayID == display.displayID }) {
                    return
                }
            case .window(let window):
                if windows.contains(where: { $0.windowID == window.windowID }) {
                    return
                }
            }

            self.selectedVideoSource = nil
        }

        if let display = displays.first {
            selectedVideoSource = .display(display)
        } else if let window = windows.first {
            selectedVideoSource = .window(window)
        }
    }
}
