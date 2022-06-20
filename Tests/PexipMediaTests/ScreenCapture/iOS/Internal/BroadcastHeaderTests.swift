#if os(iOS)

import XCTest
import CoreVideo
import ImageIO
@testable import PexipMedia

final class BroadcastHeaderTests: XCTestCase {
    func testEncodingDecoding() {
        let header = BroadcastHeader(
            displayTimeNs: mach_absolute_time(),
            pixelFormat: kCVPixelFormatType_30RGB,
            videoWidth: 1920,
            videoHeight: 1080,
            videoOrientation: CGImagePropertyOrientation.up.rawValue,
            contentLength: 100
        )

        var data = header.encodedData
        let decodedHeader = data.withUnsafeMutableBytes { buffer in
            BroadcastHeader(buffer)
        }

        XCTAssertEqual(decodedHeader, header)
    }

    func testInitWithEmptyBuffer() {
        var data = Data()
        let decodedHeader = data.withUnsafeMutableBytes { buffer in
            BroadcastHeader(buffer)
        }
        XCTAssertNil(decodedHeader)
    }

    func testEncodedSize() {
        XCTAssertEqual(BroadcastHeader.encodedSize, 28)
    }
}

#endif
