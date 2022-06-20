#if os(iOS)

import XCTest
import Combine
import CoreMedia
@testable import PexipMedia

final class BroadcastScreenVideoCapturerTests: XCTestCase {
    private let appGroup = "test"
    private let notificationCenter = BroadcastNotificationCenter.default
    private var userDefaults: UserDefaults!
    private var fileManager: BroadcastFileManagerMock!
    private var delegate: ScreenVideoCapturerDelegateMock!
    private var videoCapturer: BroadcastScreenVideoCapturer!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        userDefaults = UserDefaults(suiteName: appGroup)
        userDefaults.broadcastFps = nil

        fileManager = BroadcastFileManagerMock()
        delegate = ScreenVideoCapturerDelegateMock()

        videoCapturer = BroadcastScreenVideoCapturer(
            appGroup: appGroup,
            broadcastUploadExtension: "test",
            fileManager: fileManager
        )
        videoCapturer.delegate = delegate
    }

    override func tearDown() {
        super.tearDown()
        userDefaults.removePersistentDomain(forName: appGroup)
        videoCapturer = nil
    }

    // MARK: - Tests

    func testStartCapture() async throws {
        let fps: UInt = 15
        try await videoCapturer.startCapture(withFps: fps)

        XCTAssertEqual(userDefaults.broadcastFps, fps)
    }

    func testStartCaptureWhenCapturing() throws {
        let expectation = self.expectation(description: "Message received")
        let filePath = fileManager.broadcastSocketPath(appGroup: appGroup)
        let client = BroadcastClient(filePath: filePath)
        let fps: UInt = 15
        let handler = BroadcastSampleHandler(client: client, fps: fps)

        client.sink { [unowned self] event in
            switch event {
            case .connect:
                Task {
                    try await videoCapturer.startCapture(withFps: 5)
                    XCTAssertEqual(userDefaults.broadcastFps, fps)
                    expectation.fulfill()
                }
            case .stop:
                break
            }
        }.store(in: &cancellables)

        Task {
            try await videoCapturer.startCapture(withFps: fps)
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
        let handler = BroadcastSampleHandler(client: client, fps: 15)

        client.sink { event in
            switch event {
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
            try await videoCapturer.startCapture(withFps: 15)
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
            try await videoCapturer.startCapture(withFps: 15)
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
            try await videoCapturer.startCapture(withFps: 15)
            handler.broadcastFinished()
        }

        wait(for: [stopExpectation], timeout: 0.3)
    }

    func testBroadcastFinishedWithError() throws {
        let stopExpectation = self.expectation(description: "Broadcast finished")
        let filePath = fileManager.broadcastSocketPath(appGroup: appGroup)
        let client = BroadcastClient(filePath: filePath)
        let handler = BroadcastSampleHandler(client: client, fps: 15)

        client.sink { [unowned self] event in
            switch event {
            case .connect:
                fileManager.fileError = URLError(.badURL)
                notificationCenter.post(.broadcastFinished)
            case .stop:
                break
            }
        }.store(in: &cancellables)

        delegate.onStop = { error in
            XCTAssertEqual((error as? URLError)?.code, .badURL)
            stopExpectation.fulfill()
        }

        Task {
            try await videoCapturer.startCapture(withFps: 15)
            handler.broadcastStarted()
        }

        wait(for: [stopExpectation], timeout: 0.3)
    }
}

#endif
