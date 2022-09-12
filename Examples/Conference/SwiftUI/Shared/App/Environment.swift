import SwiftUI
import PexipInfinityClient

extension EnvironmentValues {
    var viewFactory: ViewFactory {
        get { self[ViewFactoryKey.self] }
        set { self[ViewFactoryKey.self] = newValue }
    }
}

// MARK: - Keys

private struct ViewFactoryKey: EnvironmentKey {
    static let defaultValue = ViewFactory(
        apiClientFactory: InfinityClientFactory(),
        settings: Settings()
    )
}
