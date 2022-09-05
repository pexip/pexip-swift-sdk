import Foundation
@testable import PexipInfinityClient

final class TokenRefresherMock: TokenRefresher {
    var isRefreshing: Bool {
        get async {
            _isRefreshing
        }
    }

    private(set) var withTokenRelease = false
    private(set) var onError: ((Error) -> Void)?
    private var _isRefreshing = false

    func startRefreshing(onError: ((Error) -> Void)?) async -> Bool {
        _isRefreshing = true
        self.onError = onError
        return true
    }

    func endRefreshing(withTokenRelease: Bool) async -> Bool {
        _isRefreshing = false
        self.withTokenRelease = withTokenRelease
        return true
    }
}
