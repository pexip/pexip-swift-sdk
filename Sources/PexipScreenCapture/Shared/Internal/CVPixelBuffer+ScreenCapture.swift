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

    func lockBaseAddress(_ flags: CVPixelBufferLockFlags) {
        CVPixelBufferLockBaseAddress(self, flags)
    }

    func unlockBaseAddress(_ flags: CVPixelBufferLockFlags) {
        CVPixelBufferUnlockBaseAddress(self, flags)
    }
}
