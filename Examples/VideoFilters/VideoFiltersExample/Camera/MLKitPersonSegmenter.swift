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

import AVFoundation
import PexipVideoFilters
import MLKit
import MLKitSegmentationSelfie

final class MLKitPersonSegmenter: PersonSegmenter {
    let segmenter: Segmenter
    private var currentOrientation: UIDeviceOrientation = .portrait
    private var observer: NSObjectProtocol?

    // MARK: - Init

    init(notificationCenter: NotificationCenter = .default) {
        let options = SelfieSegmenterOptions()
        options.segmenterMode = .stream
        options.shouldEnableRawSizeMask = true
        segmenter = Segmenter.segmenter(options: options)

        observer = notificationCenter.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            let windowScene = UIApplication.shared.keyWindow?.windowScene

            if let interfaceOrientation = windowScene?.interfaceOrientation {
                self?.currentOrientation = interfaceOrientation.deviceOrientation
            }
        }
    }

    // MARK: - PersonSegmenter

    func personMaskPixelBuffer(from pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        guard let sampleBuffer = sampleBuffer(from: pixelBuffer) else {
            return nil
        }

        let image = VisionImage(buffer: sampleBuffer)
        image.orientation = imageOrientation()

        do {
            let mask = try segmenter.results(in: image)
            return mask.buffer
        } catch {
            return nil
        }
    }

    // MARK: - Private

    private func sampleBuffer(from pixelBuffer: CVPixelBuffer) -> CMSampleBuffer? {
        var sampleBuffer: CMSampleBuffer?
        var timimgInfo = CMSampleTimingInfo()
        var formatDescription: CMFormatDescription?

        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )

        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: formatDescription!,
            sampleTiming: &timimgInfo,
            sampleBufferOut: &sampleBuffer
        )

        return sampleBuffer
    }

    private func imageOrientation(
        fromDevicePosition devicePosition: AVCaptureDevice.Position = .front
    ) -> UIImage.Orientation {
        var deviceOrientation = UIDevice.current.orientation

        // swiftlint:disable opening_brace
        if deviceOrientation == .faceDown
            || deviceOrientation == .faceUp
            || deviceOrientation == .unknown
        {
            deviceOrientation = currentOrientation
        }
        // swiftlint:enable opening_brace

        switch deviceOrientation {
        case .portrait:
            return devicePosition == .front ? .leftMirrored : .right
        case .landscapeLeft:
            return devicePosition == .front ? .downMirrored : .up
        case .portraitUpsideDown:
            return devicePosition == .front ? .rightMirrored : .left
        case .landscapeRight:
            return devicePosition == .front ? .upMirrored : .down
        case .faceDown, .faceUp, .unknown:
            return .up
        @unknown default:
            fatalError("Unknown device orientation")
        }
    }
}

// MARK: - Private extensions

private extension UIApplication {
    var keyWindow: UIWindow? {
        connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .first { $0.isKeyWindow }
    }
}

private extension UIInterfaceOrientation {
    var deviceOrientation: UIDeviceOrientation {
        switch self {
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .portrait, .unknown:
            return .portrait
        @unknown default:
            fatalError("Unknown device orientation")
        }
    }
}
