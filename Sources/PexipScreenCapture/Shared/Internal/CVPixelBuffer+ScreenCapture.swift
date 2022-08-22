import Foundation
import CoreVideo

extension CVPixelBuffer {
    var pixelFormat: UInt32 {
        CVPixelBufferGetPixelFormatType(self)
    }

    var width: UInt32 {
        UInt32(CVPixelBufferGetWidth(self))
    }

    var height: UInt32 {
        UInt32(CVPixelBufferGetHeight(self))
    }

    /// Requires that the buffer base address be locked
    var data: Data? {
        lockBaseAddress(.readOnly)

        defer {
            unlockBaseAddress(.readOnly)
        }

        var planes = [Plane]()
        var totalSize = 0

        for index in 0..<planeCount {
            let plane = Plane(pixelBuffer: self, index: index)
            planes.append(plane)
            totalSize += plane.size
        }

        guard let pointer = malloc(totalSize) else {
            return nil
        }

        var dst = pointer

        for plane in planes {
            memcpy(dst, plane.baseAddress, plane.size)
            dst += plane.size
        }

        return Data(bytesNoCopy: pointer, count: totalSize, deallocator: .free)
    }

    static func pixelBuffer(
        fromData data: Data,
        width: Int,
        height: Int,
        pixelFormat: OSType
    ) -> CVPixelBuffer? {
        data.withUnsafeBytes { buffer in
            var pixelBuffer: CVPixelBuffer?

            let result = CVPixelBufferCreate(
                kCFAllocatorDefault,
                width,
                height,
                pixelFormat,
                nil,
                &pixelBuffer
            )

            guard let pixelBuffer = pixelBuffer, result == kCVReturnSuccess else {
                return nil
            }

            pixelBuffer.lockBaseAddress([])

            defer {
                pixelBuffer.unlockBaseAddress([])
            }

            guard var pointer = buffer.baseAddress else {
                return nil
            }

            for index in 0..<pixelBuffer.planeCount {
                let plane = Plane(pixelBuffer: pixelBuffer, index: index)
                memcpy(plane.baseAddress, pointer, plane.size)
                pointer += plane.size
            }

            return pixelBuffer
        }
    }

    func lockBaseAddress(_ flags: CVPixelBufferLockFlags) {
        CVPixelBufferLockBaseAddress(self, flags)
    }

    func unlockBaseAddress(_ flags: CVPixelBufferLockFlags) {
        CVPixelBufferUnlockBaseAddress(self, flags)
    }

    // MARK: - Private

    private var planeCount: Int {
        CVPixelBufferGetPlaneCount(self)
    }
}

// MARK: - Private types

private struct Plane {
    let baseAddress: UnsafeMutableRawPointer?
    let bytesPerRow: Int
    let height: Int

    var size: Int {
        height * bytesPerRow
    }

    init(pixelBuffer: CVPixelBuffer, index: Int) {
        baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, index)
        bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, index)
        height = CVPixelBufferGetHeightOfPlane(pixelBuffer, index)
    }
}
