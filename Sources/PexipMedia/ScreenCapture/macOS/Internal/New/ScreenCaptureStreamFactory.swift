#if os(macOS)

#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

@available(macOS 12.3, *)
protocol ScreenCaptureStreamFactory {
    associatedtype Content: ShareableContent where Content.Content == Content

    associatedtype Filter: ScreenCaptureContentFilter
    where Filter.W == Content.W, Filter.D == Content.D

    func createStream(
        videoSource: ScreenVideoSource,
        configuration: SCStreamConfiguration,
        delegate: SCStreamDelegate?
    ) async throws -> SCStream
}

@available(macOS 12.3, *)
extension ScreenCaptureStreamFactory {
    func createContentFilter(
        videoSource: ScreenVideoSource
    ) async throws -> Filter {
        let content = try await Content.defaultSelection()
        var filter: Filter?

        switch videoSource {
        case .display(let display):
            filter = content.displays
                .first(where: {
                    $0.displayID == display.displayID
                }).map({
                    Filter(
                        display: $0,
                        excludingWindows: []
                    )
                })
        case .window(let window):
            filter = content.windows
                .first(where: {
                    $0.windowID == window.windowID
                }).map({
                    Filter(desktopIndependentWindow: $0)
                })
        }

        if let filter = filter {
            return filter
        } else {
            throw ScreenCaptureError.noScreenVideoSourceAvailable
        }
    }
}

@available(macOS 12.3, *)
struct SCStreamFactory: ScreenCaptureStreamFactory {
    typealias Content = SCShareableContent
    typealias Filter = SCContentFilter

    func createStream(
        videoSource: ScreenVideoSource,
        configuration: SCStreamConfiguration,
        delegate: SCStreamDelegate?
    ) async throws -> SCStream {
        SCStream(
            filter: try await createContentFilter(videoSource: videoSource),
            configuration: configuration,
            delegate: delegate
        )
    }
}

#endif
