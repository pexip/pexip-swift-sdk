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

final class BroadcastAudioReceiverTests: XCTestCase {
    private var receiver: BroadcastAudioReceiver!
    private let filePath = NSTemporaryDirectory().appending("/test")
    private let fileManager = FileManager.default

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        receiver = BroadcastAudioReceiver(filePath: filePath)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        try receiver?.stop()
        try? fileManager.removeItem(atPath: filePath)
    }

    // MARK: - Tests

    func testStart() throws {
        let started = try receiver.start()

        XCTAssertTrue(started)
        XCTAssertTrue(receiver.isRunning)
        XCTAssertTrue(fileManager.fileExists(atPath: filePath))
    }

    func testStartWhenRunning() throws {
        XCTAssertTrue(try receiver.start())
        XCTAssertTrue(receiver.isRunning)

        XCTAssertFalse(try receiver.start())
        XCTAssertTrue(receiver.isRunning)
    }

    func testStartWithNoFileCreated() throws {
        // 1. Create receiver with invalid file path
        receiver = BroadcastAudioReceiver(filePath: "")

        // 2. Try to start receiver
        do {
            try receiver.start()
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? BroadcastError, .noConnection)
        }
    }

    func testReceive() throws {
        let expectation = self.expectation(description: "Receive audio frame")
        let sender = BroadcastAudioSender(filePath: filePath)
        let delegate = BroadcastAudioReceiverDelegateMock()

        delegate.onReceive = { audioFrame in
            XCTAssertEqual(audioFrame.streamDescription.mSampleRate, 44100)
            expectation.fulfill()
        }

        receiver.delegate = delegate
        try receiver.start()
        try sender.start()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            sender.send(.audioStub())
        }

        wait(for: [expectation], timeout: 1)
    }

    func testStop() throws {
        try receiver.start()
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
        try receiver.start()
        XCTAssertTrue(fileManager.fileExists(atPath: filePath))

        receiver = nil
        XCTAssertFalse(fileManager.fileExists(atPath: filePath))
    }
}

// MARK: - Mocks

final class BroadcastAudioReceiverDelegateMock: BroadcastAudioReceiverDelegate {
    var onReceive: ((AudioFrame) -> Void)?

    func broadcastAudioReceiver(
        _ receiver: BroadcastAudioReceiver,
        didReceiveAudioFrame frame: AudioFrame
    ) {
        onReceive?(frame)
    }
}

#endif
