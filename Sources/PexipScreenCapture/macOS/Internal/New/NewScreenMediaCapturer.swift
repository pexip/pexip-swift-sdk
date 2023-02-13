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
import Combine
import CoreMedia

#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

/**
 ScreenCaptureKit -based screen media capturer.
 https://developer.apple.com/documentation/screencapturekit
 */
@available(macOS 12.3, *)
final class NewScreenMediaCapturer<Factory: ScreenCaptureStreamFactory>: NSObject,
    ScreenMediaCapturer,
    SCStreamOutput,
    SCStreamDelegate
{
    let source: ScreenMediaSource
    weak var delegate: ScreenMediaCapturerDelegate?
    private(set) var isCapturing = false

    private let streamFactory: Factory
    private var stream: SCStream?
    private let dispatchQueue = DispatchQueue(
        label: "com.pexip.PexipScreenCapture.NewScreenMediaCapturer",
        qos: .userInteractive
    )

    // MARK: - Init

    init(source: ScreenMediaSource, streamFactory: Factory) {
        self.source = source
        self.streamFactory = streamFactory
    }

    deinit {
        try? stream?.removeStreamOutput(self, type: .screen)
        stream?.stopCapture(completionHandler: { _ in })
    }

    // MARK: - ScreenMediaCapturer

    func startCapture(
        atFps fps: UInt,
        outputDimensions: CMVideoDimensions
    ) async throws {
        try await stopCapture()

        let streamConfig = SCStreamConfiguration()
        streamConfig.backgroundColor = .black
        streamConfig.pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        streamConfig.minimumFrameInterval = CMTime(fps: fps)
        streamConfig.width = Int(outputDimensions.width)
        streamConfig.height = Int(outputDimensions.height)

        stream = try await streamFactory.createStream(
            mediaSource: source,
            configuration: streamConfig,
            delegate: nil
        )

        try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: dispatchQueue)
        try await stream?.startCapture()
        isCapturing = true
    }

    func stopCapture() async throws {
        isCapturing = false
        try stream?.removeStreamOutput(self, type: .screen)
        try await stream?.stopCapture()
        stream = nil
    }

    // MARK: - SCStreamOutput

    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        guard let attachments = (CMSampleBufferGetSampleAttachmentsArray(
            sampleBuffer,
            createIfNecessary: false
        ) as? [[SCStreamFrameInfo: Any]])?.first else {
            return
        }

        guard let statusRawValue = attachments[.status] as? Int,
              let status = SCFrameStatus(rawValue: statusRawValue)
        else {
            return
        }

        guard let displayTime = attachments[.displayTime] as? UInt64 else {
            return
        }

        // Retrieve the content rectangle, scale, and scale factor.
        // swiftlint:disable force_cast
        guard let contentRectDict = attachments[.contentRect],
              var contentRect = CGRect(dictionaryRepresentation: contentRectDict as! CFDictionary),
              let scaleFactor = attachments[.scaleFactor] as? CGFloat
        else {
            return
        }

        let transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        contentRect = contentRect.applying(transform)

        let displayTimeNs = MachAbsoluteTime(displayTime).nanoseconds

        switch status {
        case .idle, .blank, .suspended, .started:
            break
        case .stopped:
            if isCapturing {
                isCapturing = false
                delegate?.screenMediaCapturer(self, didStopWithError: nil)
            }
        case .complete:
            if let pixelBuffer = sampleBuffer.imageBuffer {
                let videoFrame = VideoFrame(
                    pixelBuffer: pixelBuffer,
                    contentRect: contentRect,
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
