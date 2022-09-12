import Foundation
import Combine
@testable import PexipInfinityClient

final class TokenRefreshTaskMock: TokenRefreshTask {
    var eventPublisher: AnyPublisher<TokenRefreshTaskEvent, Never> {
        subject.eraseToAnyPublisher()
    }

    let subject = PassthroughSubject<TokenRefreshTaskEvent, Never>()
    private(set) var isCancelCalled = false
    private(set) var isCancelAndReleaseCalled = false

    func cancel() {
        isCancelCalled = true
    }

    func cancelAndRelease() {
        isCancelAndReleaseCalled = true
    }
}
