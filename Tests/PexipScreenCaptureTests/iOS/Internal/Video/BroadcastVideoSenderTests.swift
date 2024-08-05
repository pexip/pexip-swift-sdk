//
// Copyright -2024 Pexip AS
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

final class BroadcastVideoSenderTests: XCTestCase {
    private var sender: BroadcastVideoSender!
    private let filePath = NSTemporaryDirectory().appending("/test")
    private let fileManager = FileManager.default
    private let fps = BroadcastFps(value: 15)

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        sender = BroadcastVideoSender(filePath: filePath)
        _ = try fileManager.createMappedFile(
            atPath: filePath,
            size: BroadcastVideoReceiver.maxFileSize
        )
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        sender.stop()
        try? fileManager.removeItem(atPath: filePath)
    }

    // MARK: - Tests

    func testStart() throws {
        XCTAssertTrue(try sender.start(withFps: fps))
        XCTAssertTrue(sender.isRunning)
    }

    func testStartWhenRunning() throws {
        XCTAssertTrue(try sender.start(withFps: fps))
        XCTAssertTrue(sender.isRunning)

        XCTAssertFalse(try sender.start(withFps: fps))
        XCTAssertTrue(sender.isRunning)
    }

    func testStartWithNoFile() throws {
        // 1. Create receiver with invalid file path
        sender = BroadcastVideoSender(filePath: "test")

        // 2. Try to start sender
        do {
            try sender.start(withFps: fps)
        } catch {
            XCTAssertEqual(error as? BroadcastError, .noConnection)
        }
    }

    func testSend() throws {
        let expectation = self.expectation(description: "Receive video frame")
        let receiver = BroadcastVideoReceiver(filePath: filePath)
        let delegate = BroadcastVideoReceiverDelegateMock()
        let width = 1920
        let height = 1080
        let sampleBuffer = CMSampleBuffer.stub(width: width, height: height)

        delegate.onReceive = { videoFrame in
            XCTAssertEqual(Int(videoFrame.width), width)
            XCTAssertEqual(Int(videoFrame.height), height)
            expectation.fulfill()
        }

        receiver.delegate = delegate
        try receiver.start(withFps: fps)
        try sender.start(withFps: fps)

        XCTAssertFalse(sender.send(sampleBuffer))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            XCTAssertEqual(self?.sender.send(sampleBuffer), true)
        }

        wait(for: [expectation], timeout: 1)
    }

    func testStop() throws {
        try sender.start(withFps: fps)
        XCTAssertTrue(sender.isRunning)

        sender.stop()
        XCTAssertFalse(sender.isRunning)
    }

    func testStopWhenNotRunning() {
        XCTAssertFalse(sender.stop())
    }
}

#endif
