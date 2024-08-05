//
// Copyright 2022-2024 Pexip AS
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
import AVFoundation
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
                                                                         SCStreamDelegate {
    let source: ScreenMediaSource
    let capturesAudio: Bool
    weak var delegate: ScreenMediaCapturerDelegate?
    private(set) var isCapturing = false

    private let streamFactory: Factory
    private var stream: SCStream?
    private let videoSampleBufferQueue = DispatchQueue(
        label: "com.pexip.PexipScreenCapture.videoSampleBufferQueue",
        qos: .userInteractive
    )
    private let audioSampleBufferQueue = DispatchQueue(
        label: "com.pexip.PexipScreenCapture.audioSampleBufferQueue",
        qos: .userInteractive
    )

    // MARK: - Init

    init(source: ScreenMediaSource, capturesAudio: Bool, streamFactory: Factory) {
        self.source = source
        self.capturesAudio = capturesAudio
        self.streamFactory = streamFactory
    }

    deinit {
        try? stream?.removeStreamOutput(self, type: .screen)
        if #available(macOS 13.0, *) {
            if capturesAudio {
                try? stream?.removeStreamOutput(self, type: .audio)
            }
        }
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
        if #available(macOS 13.0, *) {
            streamConfig.capturesAudio = capturesAudio
        }

        stream = try await streamFactory.createStream(
            mediaSource: source,
            configuration: streamConfig,
            delegate: nil
        )

        try stream?.addStreamOutput(
            self,
            type: .screen,
            sampleHandlerQueue: videoSampleBufferQueue
        )
        if #available(macOS 13.0, *) {
            if capturesAudio {
                try stream?.addStreamOutput(
                    self,
                    type: .audio,
                    sampleHandlerQueue: audioSampleBufferQueue
                )
            }
        }
        try await stream?.startCapture()
        isCapturing = true
    }

    func stopCapture() async throws {
        isCapturing = false
        try stream?.removeStreamOutput(self, type: .screen)
        if #available(macOS 13.0, *) {
            if capturesAudio {
                try stream?.removeStreamOutput(self, type: .audio)
            }
        }
        try await stream?.stopCapture()
        stream = nil
    }

    // MARK: - SCStreamOutput

    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        switch type {
        case .screen:
            handleVideoSampleBuffer(sampleBuffer)
        case .audio:
            if capturesAudio {
                handleAudioSampleBuffer(sampleBuffer)
            }
        @unknown default:
            break
        }
    }

    private func handleVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
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
        // swiftlint:enable force_cast

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

    private func handleAudioSampleBuffer(_ buffer: CMSampleBuffer) {
        try? buffer.withAudioBufferList { list, _ in
            guard
                let streamDescription = buffer.formatDescription?.audioStreamBasicDescription,
                let firstBuffer = list.first,
                let firstBufferPointer = firstBuffer.mData
            else {
                return
            }

            let frame = AudioFrame(
                streamDescription: streamDescription,
                data: Data(
                    bytesNoCopy: firstBufferPointer,
                    count: Int(firstBuffer.mDataByteSize) * list.count,
                    deallocator: .none
                )
            )

            delegate?.screenMediaCapturer(self, didCaptureAudioFrame: frame)
        }
    }
}

#endif
