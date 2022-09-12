import SwiftUI

extension GeometryProxy {
    var isLandscape: Bool {
        size.width >= size.height
    }
}
