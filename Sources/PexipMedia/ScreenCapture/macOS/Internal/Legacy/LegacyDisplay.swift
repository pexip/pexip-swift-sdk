#if os(macOS)

import CoreGraphics

struct LegacyDisplay: Display, Hashable {
    let displayID: CGDirectDisplayID
    let width: Int
    let height: Int
}

// MARK: - Init

extension LegacyDisplay {
    init?(
        displayID: CGDirectDisplayID,
        displayMode: (CGDirectDisplayID) -> DisplayMode? = {
            CGDisplayCopyDisplayMode($0)
        }
    ) {
        guard let displayMode = displayMode(displayID) else {
            return nil
        }

        self.displayID = displayID
        self.width = displayMode.width
        self.height = displayMode.height
    }
}

// MARK: - Helper types

protocol DisplayMode {
    var width: Int { get }
    var height: Int { get }
}

extension CGDisplayMode: DisplayMode {}

#endif
