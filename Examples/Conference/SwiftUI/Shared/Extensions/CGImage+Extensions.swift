import SwiftUI

extension CGImage {
    static func withName(_ name: String) -> CGImage? {
        #if os(iOS)
        return UIImage(named: "background_image")?.cgImage
        #else
        return NSImage(named: "background_image")?.cgImage(
            forProposedRect: nil,
            context: nil,
            hints: nil
        )
        #endif
    }
}
