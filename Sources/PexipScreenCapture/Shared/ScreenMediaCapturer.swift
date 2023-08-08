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

import CoreVideo
import Combine
import CoreMedia

// MARK: - ScreenMediaCapturerDelegate

public protocol ScreenMediaCapturerDelegate: AnyObject {
    func screenMediaCapturer(
        _ capturer: ScreenMediaCapturer,
        didCaptureVideoFrame frame: VideoFrame
    )

    #if os(iOS)

    func screenMediaCapturerDidStart(_ capturer: ScreenMediaCapturer)

    #endif

    func screenMediaCapturer(
        _ capturer: ScreenMediaCapturer,
        didStopWithError error: Error?
    )
}

// MARK: - ScreenMediaCapturer

/// A capturer that captures the screen content.
public protocol ScreenMediaCapturer: AnyObject {
    var delegate: ScreenMediaCapturerDelegate? { get set }

    #if os(iOS)

    /**
     Starts screen capture with the given fps.
     - Parameters:
        - fps: The FPS of a video stream (15...30)
     */
    func startCapture(atFps fps: UInt) async throws

    #else

    /**
     Starts screen capture with the given video quality profile.
     - Parameters:
        - fps: The FPS of a video stream (1...60)
        - outputDimensions: The dimensions of the output video.
     */
    func startCapture(
        atFps fps: UInt,
        outputDimensions: CMVideoDimensions
    ) async throws

    #endif

    /// Stops screen capture
    func stopCapture() async throws

    /**
     Stops screen capture with the given reason.

     - Parameters:
        - reason: An optional reason why screen capture was stopped.
     */
    func stopCapture(reason: ScreenCaptureStopReason?) async throws
}

#if os(macOS)

public extension ScreenMediaCapturer {
    func stopCapture(reason: ScreenCaptureStopReason?) async throws {
        // Stop reason is not so important on macOS,
        // but it's possible to override this method in your own custom implementation
        // of `ScreenMediaCapturer` if needed.
        try await stopCapture()
    }
}

#endif

// MARK: - ScreenCaptureStopReason

public enum ScreenCaptureStopReason: Int {
    case presentationStolen
    case callEnded
}
