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
