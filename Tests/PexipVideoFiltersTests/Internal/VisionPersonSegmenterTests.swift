import XCTest
import Vision
import CoreMedia
import TestHelpers
@testable import PexipVideoFilters

@available(iOS 15.0, *)
@available(macOS 12.0, *)
final class VisionPersonSegmenterTests: XCTestCase {
    private var requestHandler: RequestHandlerMock!
    private var segmenter: VisionPersonSegmenter!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        requestHandler = RequestHandlerMock()
        segmenter = VisionPersonSegmenter(requestHandler: requestHandler)
    }

    // MARK: - Tests

    func testPersonMaskPixelBuffer() throws {
        let pixelBuffer = try XCTUnwrap(CMSampleBuffer.stub().imageBuffer)
        let result = segmenter.personMaskPixelBuffer(from: pixelBuffer)
        let request = requestHandler.requests.first as? VNGeneratePersonSegmentationRequest

        XCTAssertNil(result)
        XCTAssertEqual(request?.qualityLevel, .balanced)
        XCTAssertEqual(request?.outputPixelFormat, kCVPixelFormatType_OneComponent8)
        XCTAssertEqual(requestHandler.pixelBuffer, pixelBuffer)
        XCTAssertEqual(requestHandler.orientation, .right)
    }
}

// MARK: - Mocks

private final class RequestHandlerMock: VNSequenceRequestHandler {
    private(set) var requests = [VNRequest]()
    private(set) var pixelBuffer: CVPixelBuffer?
    private(set) var orientation: CGImagePropertyOrientation?

    override func perform(
        _ requests: [VNRequest],
        on pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation
    ) throws {
        self.requests = requests
        self.pixelBuffer = pixelBuffer
        self.orientation = orientation
    }
}
