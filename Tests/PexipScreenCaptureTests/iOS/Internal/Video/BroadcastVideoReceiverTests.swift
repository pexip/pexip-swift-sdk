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

#if os(iOS)

import XCTest
import CoreMedia
@testable import PexipScreenCapture

final class BroadcastVideoReceiverTests: XCTestCase {
    private var receiver: BroadcastVideoReceiver!
    private let filePath = NSTemporaryDirectory().appending("/test")
    private let fileManager = FileManager.default
    private let fps = BroadcastFps(value: 30)

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        receiver = BroadcastVideoReceiver(filePath: filePath)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        try receiver?.stop()
        try? fileManager.removeItem(atPath: filePath)
    }

    // MARK: - Tests

    func testStart() throws {
        let started = try receiver.start(withFps: fps)
        let attributes = try fileManager.attributesOfItem(atPath: filePath) as NSDictionary

        XCTAssertTrue(started)
        XCTAssertTrue(receiver.isRunning)
        XCTAssertTrue(fileManager.fileExists(atPath: filePath))
        XCTAssertEqual(attributes.fileSize(), UInt64(10 * 1024 * 1024))
    }

    func testStartWhenRunning() throws {
        XCTAssertTrue(try receiver.start(withFps: fps))
        XCTAssertTrue(receiver.isRunning)

        XCTAssertFalse(try receiver.start(withFps: fps))
        XCTAssertTrue(receiver.isRunning)
    }

    func testStartWithNoFileCreated() throws {
        // 1. Create receiver with invalid file path
        receiver = BroadcastVideoReceiver(filePath: "")

        // 2. Try to start receiver
        do {
            try receiver.start(withFps: fps)
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? BroadcastError, .noConnection)
        }
    }

    func testReceive() throws {
        let expectation = self.expectation(description: "Receive video frame")
        let sender = BroadcastVideoSender(filePath: filePath)
        let maxTimeInterval = CMTime(fps: fps.value)
        var lastTime: CMTime?
        var iteration = 0
        let delegate = BroadcastVideoReceiverDelegateMock()

        delegate.onReceive = { _ in
            let currentTime = CMClockGetTime(CMClockGetHostTimeClock())

            if let lastTime = lastTime {
                let delta = CMTimeSubtract(currentTime, lastTime)

                XCTAssertEqual(
                    delta.seconds,
                    maxTimeInterval.seconds,
                    accuracy: 0.02
                )
            }

            iteration += 1
            lastTime = currentTime

            if iteration == 3 {
                expectation.fulfill()
            }
        }

        receiver.delegate = delegate
        try receiver.start(withFps: fps)
        try sender.start(withFps: fps)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            sender.send(.stub())
        }

        wait(for: [expectation], timeout: 1)
    }

    func testStop() throws {
        try receiver.start(withFps: fps)
        XCTAssertTrue(fileManager.fileExists(atPath: filePath))
        XCTAssertTrue(receiver.isRunning)

        try receiver.stop()
        XCTAssertFalse(fileManager.fileExists(atPath: filePath))
        XCTAssertFalse(receiver.isRunning)
    }

    func testStopWhenNotRunning() throws {
        XCTAssertFalse(try receiver.stop())
    }

    func testStopOnDeinit() throws {
        try receiver.start(withFps: fps)
        XCTAssertTrue(fileManager.fileExists(atPath: filePath))

        receiver = nil
        XCTAssertFalse(fileManager.fileExists(atPath: filePath))
    }
}

// MARK: - Mocks

final class BroadcastVideoReceiverDelegateMock: BroadcastVideoReceiverDelegate {
    var onReceive: ((VideoFrame) -> Void)?

    func broadcastVideoReceiver(
        _ receiver: BroadcastVideoReceiver,
        didReceiveVideoFrame frame: VideoFrame
    ) {
        onReceive?(frame)
    }
}

#endif
