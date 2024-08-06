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

#if os(iOS)

import XCTest
import CoreMedia
@testable import PexipScreenCapture

final class BroadcastAudioSenderTests: XCTestCase {
    private var sender: BroadcastAudioSender!
    private var receiver: BroadcastAudioReceiver!
    private let filePath = NSTemporaryDirectory().appending("/test")
    private let fileManager = FileManager.default

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        sender = BroadcastAudioSender(filePath: filePath)
        receiver = BroadcastAudioReceiver(filePath: filePath)
        try receiver.start()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        sender.stop()
        try receiver.stop()
        try? fileManager.removeItem(atPath: filePath)
    }

    // MARK: - Tests

    func testStart() throws {
        XCTAssertTrue(try sender.start())
        XCTAssertTrue(sender.isRunning)
    }

    func testStartWhenRunning() throws {
        XCTAssertTrue(try sender.start())
        XCTAssertTrue(sender.isRunning)

        XCTAssertFalse(try sender.start())
        XCTAssertTrue(sender.isRunning)
    }

    func testStartWithNoFile() throws {
        // 1. Create receiver with invalid file path
        sender = BroadcastAudioSender(filePath: "test")

        // 2. Try to start sender
        do {
            try sender.start()
        } catch {
            XCTAssertEqual(error as? BroadcastError, .noConnection)
        }
    }

    func testSend() throws {
        let expectation = self.expectation(description: "Receive audio frame")
        let delegate = BroadcastAudioReceiverDelegateMock()
        let sampleBuffer = CMSampleBuffer.audioStub()

        delegate.onReceive = { audioFrame in
            XCTAssertEqual(audioFrame.streamDescription.mSampleRate, 44100)
            expectation.fulfill()
        }

        receiver.delegate = delegate
        try sender.start()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            XCTAssertEqual(self?.sender.send(sampleBuffer), true)
        }

        wait(for: [expectation], timeout: 1)
    }

    func testStop() throws {
        try sender.start()
        XCTAssertTrue(sender.isRunning)

        sender.stop()
        XCTAssertFalse(sender.isRunning)
    }

    func testStopWhenNotRunning() {
        XCTAssertFalse(sender.stop())
    }
}

#endif
