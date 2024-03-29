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

import CoreGraphics
import CoreMedia

/// Call and presentation quality profile.
public struct QualityProfile: Hashable {
    public static let `default` = Self.high

    // MARK: - Video call

    /// 1280x720 (16:9)
    public static let high = QualityProfile(
        width: 1280,
        height: 720,
        fps: 30
    )

    #if os(iOS)

    /// 1920x1080 (16:9)
    public static let veryHigh = QualityProfile(
        width: 1920,
        height: 1080,
        fps: 30
    )

    /// 960x540 (16:9)
    public static let medium = QualityProfile(
        width: 960,
        height: 540,
        fps: 25
    )

    /// 480x360 (4:3)
    public static let low = QualityProfile(
        width: 480,
        height: 360,
        fps: 15
    )

    #else

    /// 640x480 (4:3)
    public static let medium = QualityProfile(
        width: 640,
        height: 480,
        fps: 30
    )

    #endif

    // MARK: - Presentation

    /// 1920x1080 (16:9)
    public static let presentationVeryHigh = QualityProfile(
        width: 1920,
        height: 1080,
        fps: 30
    )

    /// 1280x720 (16:9)
    public static let presentationHigh = Self.high

    #if os(iOS)

    /// 640x480 (4:3)
    public static let presentationMedium = QualityProfile(
        width: 640,
        height: 480,
        fps: 15
    )

    #endif

    // MARK: - Properties

    /// The width of a video stream (640...1920)
    public let width: UInt

    /// The height of a video stream (360...1080)
    public let height: UInt

    /// The FPS of a video stream (1...60)
    public let fps: UInt

    /// The aspect ratio of a video stream.
    public var aspectRatio: CGSize {
        CGSize(width: Int(width), height: Int(height))
    }

    /// The dimensions of a video stream.
    public var dimensions: CMVideoDimensions {
        CMVideoDimensions(width: Int32(width), height: Int32(height))
    }

    // MARK: - Init

    /**
     Creates a new instance of ``QualityProfile``.

     - Parameters:
        - width: the width of a video stream (640...1920)
        - height: the height of a video stream (360...1080)
        - fps: the FPS of a video stream (1...60)
     */
    public init(
        width: UInt,
        height: UInt,
        fps: UInt
    ) {
        precondition((480...1920).contains(width))
        precondition((360...1080).contains(height))
        precondition((1...60).contains(fps))

        self.width = width
        self.height = height
        self.fps = fps
    }

    // MARK: - Frame rate

    /**
     Selects best frame rate for this quality profile
     from the provided array of frame rate ranges, typically [AVFrameRateRange].

     - Parameters:
        - frameRateRanges: Frame rate ranges
        - maxFrameRate: A key path to access the max frame rate
                        of the range (e.g. \AVFrameRateRange.maxFrameRate)
     - Returns: Best frame rate
     */
    public func bestFrameRate<T>(
        from frameRateRanges: [T],
        maxFrameRate: KeyPath<T, Float64>
    ) -> Float64? {
        let targetFrameRate = Float64(fps)
        var selectedFrameRate: Float64?
        var currentDiff = Float64.greatestFiniteMagnitude

        for frameRateRange in frameRateRanges {
            let maxFrameRate = frameRateRange[keyPath: maxFrameRate]
            let diff = abs(maxFrameRate - targetFrameRate)
            if diff < currentDiff {
                selectedFrameRate = maxFrameRate
                currentDiff = diff
            }
        }

        return selectedFrameRate.map {
            Swift.min($0, targetFrameRate)
        }
    }

    /**
     Selects best format from the provided array of formats,
     typically [AVCaptureDevice.Format].

     - Parameters:
        - formats: Capture device formats
        - formatDescription: A key path to access the formatDescription of the format
                             (e.g. \AVCaptureDevice.Format.formatDescription)
     - Returns: Best frame rate
     */
    public func bestFormat<T>(
        from formats: [T],
        formatDescription: KeyPath<T, CMFormatDescription>
    ) -> T? {
        let targetWidth = Int32(width)
        let targetHeight = Int32(height)
        var selectedFormat: T?
        var currentDiff = Int32.max

        for format in formats {
            let dimension = CMVideoFormatDescriptionGetDimensions(
                format[keyPath: formatDescription]
            )
            let widthDiff = abs(targetWidth - dimension.width)
            let heightDiff = abs(targetHeight - dimension.height)

            let diff = widthDiff + heightDiff
            if diff < currentDiff {
                selectedFormat = format
                currentDiff = Int32(diff)
            }
        }

        return selectedFormat
    }
}
