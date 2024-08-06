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

import Foundation
import AVFoundation

#if os(iOS)

import XCTest
@testable import PexipScreenCapture

final class AudioBufferHeaderTests: XCTestCase {
    func testEncodeDecode() {
        var header = AudioBufferHeader()
        header.dataSize = 123
        header.streamDescription.mSampleRate = 44_100

        let data = header.encoded()
        XCTAssertNotNil(data)
        XCTAssertEqual(data?.count, AudioBufferHeader.size)

        let decoded = AudioBufferHeader.decode(from: data!)
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.dataSize, 123)
        XCTAssertEqual(
            decoded?.streamDescription.mSampleRate,
            header.streamDescription.mSampleRate
        )
    }

    func testDecodeWithNoData() {
        let decoded = AudioBufferHeader.decode(from: Data())
        XCTAssertNil(decoded)
    }

    func testDecodeWithInvalidData() {
        let data = Data(count: AudioBufferHeader.size - 1)
        let decoded = AudioBufferHeader.decode(from: data)
        XCTAssertNil(decoded)
    }
}

#endif
