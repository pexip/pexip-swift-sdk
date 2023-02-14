//
// Copyright 2022-2023 Pexip AS
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
@testable import PexipScreenCapture

final class MemoryMappedFileTests: XCTestCase {
    private let fileManager = FileManager.default
    private var fileDescriptor: Int32!
    private var file: MemoryMappedFile!
    private let size = 4
    private let path = NSTemporaryDirectory().appending("/test")

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        fileDescriptor = open(path, O_RDWR | O_APPEND | O_CREAT, S_IRUSR | S_IWUSR)
        ftruncate(fileDescriptor, off_t(size))
        file = MemoryMappedFile(
            path: path,
            fileDescriptor: fileDescriptor,
            size: size
        )
    }

    override func tearDown() {
        try? fileManager.removeItem(atPath: path)
        super.tearDown()
    }

    // MARK: - Tests

    func testInit() {
        XCTAssertEqual(file.path, path)
        XCTAssertEqual(file.size, size)
        XCTAssertTrue(
            fcntl(fileDescriptor, F_GETFD) != -1 || errno != EBADF
        )
    }

    func testDeinit() {
        file = nil
        XCTAssertFalse(
            fcntl(fileDescriptor, F_GETFD) != -1 || errno != EBADF
        )
    }

    func testReadWrite() throws {
        let data = try XCTUnwrap("test".data(using: .utf8))
        XCTAssertTrue(file.write(data))
        XCTAssertEqual(file.read(), data)
    }

    func testReadWriteWithDataSizeBiggerThanFileSize() throws {
        let data = try XCTUnwrap("test2".data(using: .utf8))
        XCTAssertFalse(file.write(data))
        XCTAssertNotEqual(file.read(), data)
    }
}

#endif
