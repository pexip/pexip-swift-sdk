import SwiftUI

extension LinearGradient {
    static func defaultGradient(
        startPoint: UnitPoint,
        endPoint: UnitPoint
    ) -> some View {
        LinearGradient(
            colors: [Color.black.opacity(0.2), Color.clear],
            startPoint: startPoint,
            endPoint: endPoint
        )
        .edgesIgnoringSafeArea(.all)
    }
}
