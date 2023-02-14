//
// Copyright 2022-2023 Pexip AS
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

import AppKit
import CoreMedia
import Combine

/**
 Quartz Window Services -based display media capturer.
 https://developer.apple.com/documentation/coregraphics/quartz_window_services
 */
final class LegacyDisplayCapturer: ScreenMediaCapturer {
    let display: Display
    let displayStreamType: LegacyDisplayStream.Type
    weak var delegate: ScreenMediaCapturerDelegate?
    private(set) var isCapturing = false

    private var displayStream: LegacyDisplayStream?
    private let processingQueue = DispatchQueue(
        label: "com.pexip.PexipScreenCapture.LegacyDisplayCapturer",
        qos: .userInteractive
    )

    // MARK: - Init

    init(
        display: Display,
        displayStreamType: LegacyDisplayStream.Type = CGDisplayStream.self
    ) {
        self.display = display
        self.displayStreamType = displayStreamType
    }

    deinit {
        try? stopCapture()
    }

    // MARK: - ScreenMediaCapturer

    func startCapture(
        atFps fps: UInt,
        outputDimensions: CMVideoDimensions
    ) async throws {
        try stopCapture()

        let properties: [CFString: Any] = [
            CGDisplayStream.preserveAspectRatio: kCFBooleanTrue as Any,
            CGDisplayStream.minimumFrameTime: CMTime(fps: fps).seconds as CFNumber
        ]

        displayStream = displayStreamType.init(
            dispatchQueueDisplay: display.displayID,
            outputWidth: Int(outputDimensions.width),
            outputHeight: Int(outputDimensions.height),
            pixelFormat: Int32(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange),
            properties: properties as CFDictionary,
            queue: processingQueue,
            handler: { [weak self] status, displayTime, ioSurface, _ in
                self?.handleDisplayStream(
                    status: status,
                    displayTime: displayTime,
                    ioSurface: ioSurface
                )
            }
        )

        let result = displayStream!.start()

        if result == .success {
            isCapturing = true
        } else {
            displayStream = nil
            throw ScreenCaptureError.cgError(result)
        }
    }

    func stopCapture() throws {
        defer {
            displayStream = nil
        }

        isCapturing = false

        if let result = displayStream?.stop(), result != .success {
            throw ScreenCaptureError.cgError(result)
        }
    }

    // MARK: - Private

    private func handleDisplayStream(
        status: CGDisplayStreamFrameStatus,
        displayTime: UInt64,
        ioSurface: IOSurfaceRef?
    ) {
        let displayTimeNs = MachAbsoluteTime(displayTime).nanoseconds

        switch status {
        case .frameIdle, .frameBlank:
            break
        case .stopped:
            if isCapturing {
                isCapturing = false
                delegate?.screenMediaCapturer(self, didStopWithError: nil)
            }
        case .frameComplete:
            guard let ioSurface else {
                break
            }

            var pixelBufferRef: Unmanaged<CVPixelBuffer>?
            let attributes: [AnyHashable: Any] = [
                kCVPixelBufferIOSurfacePropertiesKey: true as AnyObject
            ]

            let result = CVPixelBufferCreateWithIOSurface(
                kCFAllocatorDefault, ioSurface,
                attributes as CFDictionary,
                &pixelBufferRef
            )

            if let pixelBufferRef, result == kCVReturnSuccess {
                let pixelBuffer = pixelBufferRef.takeRetainedValue()
                let videoFrame = VideoFrame(
                    pixelBuffer: pixelBuffer,
                    contentRect: CGRect(
                        x: 0,
                        y: 0,
                        width: Int(pixelBuffer.width),
                        height: Int(pixelBuffer.height)
                    ),
                    displayTimeNs: displayTimeNs
                )
                delegate?.screenMediaCapturer(self, didCaptureVideoFrame: videoFrame)
            }
        @unknown default:
            break
        }
    }
}

#endif
