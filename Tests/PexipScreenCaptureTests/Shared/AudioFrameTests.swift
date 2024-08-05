//
// Copyright 2024 Pexip AS
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

import XCTest
import AVFoundation
@testable import PexipScreenCapture

final class AudioFrameTests: XCTestCase {
    private let width = 1920
    private let height = 1080
    private let displayTimeNs: UInt64 = 10_000
    private let pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    private var pixelBuffer: CVPixelBuffer!
    private var videoFrame: VideoFrame!

    // MARK: - Setup

    func testIsSignedInteger() {
        do {
            let frame = AudioFrame(streamDescription: .init(), data: Data())
            XCTAssertFalse(frame.isSignedInteger)
        }

        do {
            var streamDescription = AudioStreamBasicDescription()
            streamDescription.mFormatFlags = kAudioFormatFlagIsSignedInteger
            let frame = AudioFrame(streamDescription: streamDescription, data: Data())
            XCTAssertTrue(frame.isSignedInteger)
        }
    }

    func testIsFloat() {
        do {
            let frame = AudioFrame(streamDescription: .init(), data: Data())
            XCTAssertFalse(frame.isFloat)
        }

        do {
            var streamDescription = AudioStreamBasicDescription()
            streamDescription.mFormatFlags = kAudioFormatFlagIsFloat
            let frame = AudioFrame(streamDescription: streamDescription, data: Data())
            XCTAssertTrue(frame.isFloat)
        }
    }

    func testIsInterleaved() {
        do {
            let frame = AudioFrame(streamDescription: .init(), data: Data())
            XCTAssertTrue(frame.isInterleaved)
        }

        do {
            var streamDescription = AudioStreamBasicDescription()
            streamDescription.mFormatFlags = kAudioFormatFlagIsNonInterleaved
            let frame = AudioFrame(streamDescription: streamDescription, data: Data())
            XCTAssertFalse(frame.isInterleaved)
        }
    }
}
