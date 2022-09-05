final class TestResultSender<T> {
    private var handler: ((Result<T, Error>) -> Void)?

    func setHandler(_ handler: ((Result<T, Error>) -> Void)?) {
        self.handler = handler
    }

    func send(_ result: (Result<T, Error>)) {
        handler?(result)
    }
}
