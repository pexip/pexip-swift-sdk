#if os(iOS)

import XCTest
import Combine
import CoreMedia
@testable import PexipScreenCapture

final class BroadcastScreenCapturerTests: XCTestCase {
    private let appGroup = "test"
    private let notificationCenter = BroadcastNotificationCenter.default
    private var userDefaults: UserDefaults!
    private var fileManager: BroadcastFileManagerMock!
    private var delegate: ScreenMediaCapturerDelegateMock!
    private var capturer: BroadcastScreenCapturer!
    private var cancellables = Set<AnyCancellable>()
    private let fps: UInt = 15
    private let outputDimensions = CMVideoDimensions(width: 1280, height: 720)

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        userDefaults = UserDefaults(suiteName: appGroup)
        userDefaults.broadcastFps = nil

        fileManager = BroadcastFileManagerMock()
        delegate = ScreenMediaCapturerDelegateMock()

        capturer = BroadcastScreenCapturer(
            appGroup: appGroup,
            broadcastUploadExtension: "test",
            fileManager: fileManager
        )
        capturer.delegate = delegate
    }

    override func tearDown() {
        super.tearDown()
        userDefaults.removePersistentDomain(forName: appGroup)
        capturer = nil
    }

    // MARK: - Tests

    func testStartCapture() async throws {
        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )

        XCTAssertEqual(userDefaults.broadcastFps, fps)
    }

    func testStartCaptureWhenCapturing() throws {
        let expectation = self.expectation(description: "Message received")
        let filePath = fileManager.broadcastSocketPath(appGroup: appGroup)
        let client = BroadcastClient(filePath: filePath)
        let fps: UInt = 15
        let handler = BroadcastSampleHandler(client: client, fps: fps)

        client.sink { [weak self] httpEvent in
            guard let self = self else {
                return
            }

            switch httpEvent {
            case .connect:
                Task {
                    try await self.capturer.startCapture(
                        atFps: 5,
                        outputDimensions: self.outputDimensions
                    )
                    XCTAssertEqual(self.userDefaults.broadcastFps, fps)
                    expectation.fulfill()
                }
            case .stop:
                break
            }
        }.store(in: &cancellables)

        Task {
            try await capturer.startCapture(
                atFps: fps,
                outputDimensions: outputDimensions
            )
            handler.broadcastStarted()
        }

        wait(for: [expectation], timeout: 0.3)
    }

    func testBroadcast() throws {
        let messageExpectation = self.expectation(description: "Message received")
        let stopExpectation = self.expectation(description: "Broadcast finished")

        let filePath = fileManager.broadcastSocketPath(appGroup: appGroup)
        let client = BroadcastClient(filePath: filePath)
        let width = 1920
        let height = 1080
        let sampleBuffer = CMSampleBuffer.stub(width: width, height: height)
        let handler = BroadcastSampleHandler(client: client, fps: fps)

        client.sink { httpEvent in
            switch httpEvent {
            case .connect:
                handler.processSampleBuffer(sampleBuffer, with: .video)
            case .stop:
                break
            }
        }.store(in: &cancellables)

        delegate.onVideoFrame = { videoFrame in
            XCTAssertEqual(videoFrame.width, UInt32(width))
            XCTAssertEqual(videoFrame.height, UInt32(height))
            XCTAssertEqual(videoFrame.pixelBuffer.data, sampleBuffer.imageBuffer?.data)
            handler.broadcastFinished()
            messageExpectation.fulfill()
        }

        delegate.onStop = { error in
            XCTAssertNil(error)
            stopExpectation.fulfill()
        }

        Task {
            try await capturer.startCapture(
                atFps: fps,
                outputDimensions: outputDimensions
            )
            handler.broadcastStarted()
        }

        wait(for: [messageExpectation, stopExpectation], timeout: 0.3)
    }

    func testBroadcastWithServerStartError() throws {
        fileManager.fileError = URLError(.badURL)

        let stopExpectation = self.expectation(description: "Broadcast finished")
        let handler = BroadcastSampleHandler(
            appGroup: appGroup,
            fileManager: fileManager
        )

        delegate.onStop = { error in
            XCTAssertEqual((error as? URLError)?.code, .badURL)
            stopExpectation.fulfill()
        }

        Task {
            try await capturer.startCapture(
                atFps: fps,
                outputDimensions: outputDimensions
            )
            handler.broadcastStarted()
        }

        wait(for: [stopExpectation], timeout: 0.3)
    }

    func testBroadcastFinishedWhenNotCapturing() {
        let stopExpectation = self.expectation(description: "Broadcast finished")
        stopExpectation.isInverted = true

        let handler = BroadcastSampleHandler(
            appGroup: appGroup,
            fileManager: fileManager
        )

        delegate.onStop = { _ in
            stopExpectation.fulfill()
        }

        Task {
            try await capturer.startCapture(
                atFps: fps,
                outputDimensions: outputDimensions
            )
            handler.broadcastFinished()
        }

        wait(for: [stopExpectation], timeout: 0.3)
    }

    func testBroadcastFinishedWithError() throws {
        let stopExpectation = self.expectation(description: "Broadcast finished")
        let filePath = fileManager.broadcastSocketPath(appGroup: appGroup)
        let client = BroadcastClient(filePath: filePath)
        let handler = BroadcastSampleHandler(client: client, fps: fps)

        client.sink { [weak self] httpEvent in
            guard let self = self else {
                return
            }

            switch httpEvent {
            case .connect:
                self.fileManager.fileError = URLError(.badURL)
                self.notificationCenter.post(.broadcastFinished)
            case .stop:
                break
            }
        }.store(in: &cancellables)

        delegate.onStop = { error in
            XCTAssertEqual((error as? URLError)?.code, .badURL)
            stopExpectation.fulfill()
        }

        Task {
            try await capturer.startCapture(
                atFps: fps,
                outputDimensions: outputDimensions
            )
            handler.broadcastStarted()
        }

        wait(for: [stopExpectation], timeout: 0.3)
    }
}

#endif
