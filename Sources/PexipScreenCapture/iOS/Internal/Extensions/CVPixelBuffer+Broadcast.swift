#if os(iOS)

import CoreVideo

extension CVPixelBuffer {
    struct Plane {
        let baseAddress: UnsafeMutableRawPointer?
        let bytesPerRow: Int
        let height: Int

        var size: Int {
            height * bytesPerRow
        }
    }

    var planeCount: Int {
        CVPixelBufferGetPlaneCount(self)
    }

    func plane(at index: Int) -> Plane {
        Plane(
            baseAddress: CVPixelBufferGetBaseAddressOfPlane(self, index),
            bytesPerRow: CVPixelBufferGetBytesPerRowOfPlane(self, index),
            height: CVPixelBufferGetHeightOfPlane(self, index)
        )
    }
}

#endif
