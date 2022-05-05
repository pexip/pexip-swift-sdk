import SwiftUI
import Combine

final class DisplayNameViewModel: ObservableObject {
    @AppStorage("displayName") var displayName = ""

    var isValid: Bool {
        !displayName.isEmpty
    }

    private let onComplete: () -> Void

    // MARK: - Init

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    // MARK: - Actions

    func next() async {
        if isValid {
            onComplete()
        }
    }
}
