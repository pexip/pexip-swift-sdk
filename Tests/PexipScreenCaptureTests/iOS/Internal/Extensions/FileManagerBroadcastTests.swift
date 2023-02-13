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

final class FileManagerBroadcastTests: XCTestCase {
    private let fileManager = FileManager.default
    private let size = 1024 * 1024
    private let path = NSTemporaryDirectory().appending("/test")

    // MARK: - Setup

    override func tearDown() {
        try? fileManager.removeItem(atPath: path)
        super.tearDown()
    }

    // MARK: - Tests

    func testBroadcastVideoDataPath() {
        let path = fileManager.broadcastVideoDataPath(appGroup: "Test")
        XCTAssertTrue(path.hasSuffix("pex_broadcast_video"))
    }

    func testBroadcastVideoDataPathWithNoContainerURL() {
        let fileManager = BroadcastFileManagerMock()
        fileManager.containerURL = nil

        let path = fileManager.broadcastVideoDataPath(appGroup: "Test")
        XCTAssertEqual(path, "pex_broadcast_video")
    }

    func testCreateMappedFile() throws {
        let file = try XCTUnwrap(fileManager.createMappedFile(atPath: path, size: size))
        let attributes = try fileManager.attributesOfItem(atPath: path) as NSDictionary

        XCTAssertTrue(fileManager.fileExists(atPath: path))
        XCTAssertEqual(attributes.fileSize(), UInt64(size))
        XCTAssertEqual(file.path, path)
        XCTAssertEqual(file.size, size)
    }

    func testCreateMappedFileWithExistingFile() throws {
        // 1. Create file
        _ = try fileManager.createMappedFile(atPath: path, size: size)

        // 2. Create file with new size
        let newSize = 2 * 1024 * 1024
        let file = try XCTUnwrap(fileManager.createMappedFile(atPath: path, size: newSize))
        let attributes = try fileManager.attributesOfItem(atPath: path) as NSDictionary

        // 3. Assert
        XCTAssertTrue(fileManager.fileExists(atPath: path))
        XCTAssertEqual(attributes.fileSize(), UInt64(newSize))
        XCTAssertEqual(file.path, path)
        XCTAssertEqual(file.size, newSize)
    }

    func testCreateMappedFileWithRemoveItemError() throws {
        // 1. Create file
        let fileManager = BroadcastFileManagerMock()
        _ = try fileManager.createMappedFile(atPath: path, size: size)

        // 2. Try to create file with new size
        do {
            let newSize = 2 * 1024 * 1024
            fileManager.fileError = URLError(.badURL)
            _ = try fileManager.createMappedFile(atPath: path, size: newSize)
            XCTFail("Should fail with error")
        } catch {
            let attributes = try fileManager.attributesOfItem(atPath: path) as NSDictionary

            XCTAssertEqual((error as? URLError)?.code, .badURL)
            XCTAssertTrue(fileManager.fileExists(atPath: path))
            XCTAssertEqual(attributes.fileSize(), UInt64(size))
        }
    }

    func testCreateMappedFileWithError() throws {
        // Try to create file at invalid path
        let file = try fileManager.createMappedFile(atPath: "", size: size)
        XCTAssertNil(file)
    }

    func testMappedFile() throws {
        // 1. Create file
        _ = try fileManager.createMappedFile(atPath: path, size: size)

        // 2. Open file
        let file = try XCTUnwrap(fileManager.mappedFile(atPath: path))
        let attributes = try fileManager.attributesOfItem(atPath: path) as NSDictionary

        // 3. Assert
        XCTAssertTrue(fileManager.fileExists(atPath: path))
        XCTAssertEqual(attributes.fileSize(), UInt64(size))
        XCTAssertEqual(file.path, path)
        XCTAssertEqual(file.size, size)
    }

    func testMappedFileWithError() {
        // Try to open file that doesn't exist
        let file = fileManager.mappedFile(atPath: "")
        XCTAssertNil(file)
    }
}

// MARK: - Mocks

final class BroadcastFileManagerMock: FileManager {
    var fileError: Error?
    var containerURL: URL? = URL(string: "/tmp")

    override func fileExists(atPath path: String) -> Bool {
        return fileError != nil ? true : super.fileExists(atPath: path)
    }

    override func removeItem(atPath path: String) throws {
        if let error = fileError {
            throw error
        } else {
            try super.removeItem(atPath: path)
        }
    }

    override func containerURL(
        forSecurityApplicationGroupIdentifier groupIdentifier: String
    ) -> URL? {
        return containerURL
    }
}

#endif
