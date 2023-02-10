#if os(iOS)

import Foundation

final class MemoryMappedFile {
    let path: String
    let size: Int
    private let fileDescriptor: Int32
    private var memory: UnsafeMutableRawPointer

    // MARK: - Init

    init(path: String, fileDescriptor: Int32, size: Int) {
        self.path = path
        self.fileDescriptor = fileDescriptor
        self.size = size
        memory = mmap(
            nil,
            size,
            PROT_READ | PROT_WRITE,
            MAP_SHARED,
            fileDescriptor,
            0
        )
    }

    deinit {
        munmap(memory, size)
        close(fileDescriptor)
    }

    // MARK: - Internal

    @discardableResult
    func write(_ data: Data) -> Bool {
        guard data.count <= size else {
            return false
        }

        data.withUnsafeBytes { pointer in
            if let baseAddress = pointer.baseAddress {
                memcpy(memory, baseAddress, data.count)
            }
        }

        return true
    }

    func read() -> Data {
        Data(bytesNoCopy: memory, count: size, deallocator: .none)
    }
}

#endif
