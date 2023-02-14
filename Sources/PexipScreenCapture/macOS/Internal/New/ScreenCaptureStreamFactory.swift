//
// Copyright 2022 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#if os(macOS)

#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

@available(macOS 12.3, *)
protocol ScreenCaptureStreamFactory {
    associatedtype Content: ShareableContent where Content.Content == Content

    associatedtype Filter: ScreenCaptureContentFilter
    where Filter.W == Content.W, Filter.D == Content.D, Filter.A == Content.A

    func createStream(
        mediaSource: ScreenMediaSource,
        configuration: SCStreamConfiguration,
        delegate: SCStreamDelegate?
    ) async throws -> SCStream
}

@available(macOS 12.3, *)
extension ScreenCaptureStreamFactory {
    func createContentFilter(
        mediaSource: ScreenMediaSource
    ) async throws -> Filter {
        let content = try await Content.defaultSelection()
        var filter: Filter?

        switch mediaSource {
        case .display(let display):
            filter = content.displays
                .first(where: {
                    $0.displayID == display.displayID
                }).map({
                    Filter(
                        display: $0,
                        excludingApplications: content.applications.filter { app in
                            app.bundleIdentifier == Bundle.main.bundleIdentifier
                        },
                        exceptingWindows: []
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

        if let filter {
            return filter
        } else {
            throw ScreenCaptureError.noScreenMediaSourceAvailable
        }
    }
}

@available(macOS 12.3, *)
struct SCStreamFactory: ScreenCaptureStreamFactory {
    typealias Content = SCShareableContent
    typealias Filter = SCContentFilter

    func createStream(
        mediaSource: ScreenMediaSource,
        configuration: SCStreamConfiguration,
        delegate: SCStreamDelegate?
    ) async throws -> SCStream {
        SCStream(
            filter: try await createContentFilter(mediaSource: mediaSource),
            configuration: configuration,
            delegate: delegate
        )
    }
}

#endif
