#if os(macOS)

import CoreGraphics

protocol LegacyDisplayStream {
    init?(
        dispatchQueueDisplay display: CGDirectDisplayID,
        outputWidth: Int,
        outputHeight: Int,
        pixelFormat: Int32,
        properties: CFDictionary?,
        queue: DispatchQueue,
        handler: CGDisplayStreamFrameAvailableHandler?
    )

    func start() -> CGError
    func stop() -> CGError
}

extension CGDisplayStream: LegacyDisplayStream {}

#endif
