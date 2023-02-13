//
// Copyright 2022 Pexip AS
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
import CoreGraphics
import TestHelpers
@testable import PexipVideoFilters

final class CoreGraphicsVideoFiltersTests: XCTestCase {
    func testCGImageScaledToFill() {
        let image = CGImage.image(width: 100, height: 100)
        let scaledImage = image?.scaledToFill(.init(width: 80, height: 50))

        XCTAssertEqual(scaledImage?.width, 80)
        XCTAssertEqual(scaledImage?.height, 50)
    }

    func testCGSizeAspectFillSize() {
        var size = CGSize(width: 100, height: 80).aspectFillSize(
            for: CGSize(width: 100, height: 100)
        )
        XCTAssertEqual(size.width, 125)
        XCTAssertEqual(size.height, 100)

        size = CGSize(width: 80, height: 100).aspectFillSize(
            for: CGSize(width: 100, height: 100)
        )
        XCTAssertEqual(size.width, 100)
        XCTAssertEqual(size.height, 125)
    }

    func testCGImagePropertyOrientationIsVertical() {
        XCTAssertTrue(CGImagePropertyOrientation.up.isVertical)
        XCTAssertTrue(CGImagePropertyOrientation.upMirrored.isVertical)
        XCTAssertTrue(CGImagePropertyOrientation.down.isVertical)
        XCTAssertTrue(CGImagePropertyOrientation.downMirrored.isVertical)

        XCTAssertFalse(CGImagePropertyOrientation.left.isVertical)
        XCTAssertFalse(CGImagePropertyOrientation.leftMirrored.isVertical)
        XCTAssertFalse(CGImagePropertyOrientation.right.isVertical)
        XCTAssertFalse(CGImagePropertyOrientation.rightMirrored.isVertical)
        XCTAssertFalse(CGImagePropertyOrientation(rawValue: 1001)?.isVertical == true)
    }
}
