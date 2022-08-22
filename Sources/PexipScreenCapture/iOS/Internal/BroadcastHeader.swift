#if os(iOS)

import Foundation

struct BroadcastHeader: Hashable {
    let displayTimeNs: UInt64
    let pixelFormat: UInt32
    let videoWidth: UInt32
    let videoHeight: UInt32
    let videoOrientation: UInt32
    let contentLength: UInt32
}

// MARK: - Encoding/decoding

extension BroadcastHeader {
    init?(_ buffer: UnsafeMutableRawBufferPointer) {
        guard let baseAddress = buffer.baseAddress, buffer.count > 0 else {
            return nil
        }

        func copyMemory<T>(to value: inout T, offset: Int) -> Int {
            let count = MemoryLayout<T>.size

            withUnsafeMutableBytes(of: &value) { pointer in
                pointer.copyMemory(from: UnsafeRawBufferPointer(
                    start: baseAddress.advanced(by: offset),
                    count: count
                ))
            }

            return offset + count
        }

        var displayTimeNs: UInt64 = 0
        var pixelFormat: UInt32 = 0
        var videoWidth: UInt32 = 0
        var videoHeight: UInt32 = 0
        var videoOrientation: UInt32 = 0
        var contentLength: UInt32 = 0
        var position = 0

        position = copyMemory(to: &displayTimeNs, offset: position)
        position = copyMemory(to: &pixelFormat, offset: position)
        position = copyMemory(to: &videoWidth, offset: position)
        position = copyMemory(to: &videoHeight, offset: position)
        position = copyMemory(to: &videoOrientation, offset: position)
        position = copyMemory(to: &contentLength, offset: position)

        self.init(
            displayTimeNs: displayTimeNs,
            pixelFormat: pixelFormat,
            videoWidth: videoWidth,
            videoHeight: videoHeight,
            videoOrientation: videoOrientation,
            contentLength: contentLength
        )
    }

    var encodedData: Data {
        var displayTimeNs = self.displayTimeNs
        var pixelFormat = self.pixelFormat
        var videoWidth = self.videoWidth
        var videoHeight = self.videoHeight
        var videoOrientation = self.videoOrientation
        var contentLength = self.contentLength

        var data = Data(bytes: &displayTimeNs, count: MemoryLayout<UInt64>.size)
        data.append(Data(bytes: &pixelFormat, count: MemoryLayout<UInt32>.size))
        data.append(Data(bytes: &videoWidth, count: MemoryLayout<UInt32>.size))
        data.append(Data(bytes: &videoHeight, count: MemoryLayout<UInt32>.size))
        data.append(Data(bytes: &videoOrientation, count: MemoryLayout<UInt32>.size))
        data.append(Data(bytes: &contentLength, count: MemoryLayout<UInt32>.size))

        return data
    }

    static var encodedSize: Int {
        MemoryLayout<UInt64>.size + MemoryLayout<UInt32>.size * 5
    }
}

#endif
