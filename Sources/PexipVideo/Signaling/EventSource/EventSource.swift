import Foundation

/// Implementation of the W3C SSE spec
/// https://html.spec.whatwg.org/multipage/server-sent-events.html
final class EventSource {
    static func eventStream(
        withRequest request: URLRequest,
        lastEventId: String? = nil,
        urlSessionConfiguration: URLSessionConfiguration = .ephemeral,
        urlSessionDelegate: URLSessionDelegate? = nil
    ) -> AsyncThrowingStream<MessageEvent, Error> {
        AsyncThrowingStream { continuation in
             let eventSource = EventSource(
                request: request,
                lastEventId: lastEventId,
                urlSessionConfiguration: urlSessionConfiguration,
                urlSessionDelegate: urlSessionDelegate
             )
             eventSource.onReceive = { event in
                 continuation.yield(event)
             }
             eventSource.onComplete = { response, error in
                 continuation.finish(
                    throwing: EventSourceError(
                        response: response,
                        dataStreamError: error
                    )
                 )
             }
             continuation.onTermination = { @Sendable _ in
                 eventSource.close()
             }
             eventSource.open()
         }
    }

    private var onReceive: ((MessageEvent) -> Void)?
    private var onComplete: ((HTTPURLResponse?, Error?) -> Void)?
    private let configuration: URLSessionConfiguration
    private let request: URLRequest
    private var urlSession: URLSession?
    private let dataTaskDelegate = DataTaskDelegate()
    private let parser = EventStreamParser()

    // MARK: - Init

    /**
     - Parameters:
        - request: URL request for SSE
        - lastEventId: optional last event ID used to reestablish the connection
        - urlSessionConfiguration: `URLSession` configuration object
        - urlSessionDelegate: optional `URLSession` delegate to be notified about
        important network events, such as authentication challenges
     */
    private init(
        request: URLRequest,
        lastEventId: String? = nil,
        urlSessionConfiguration: URLSessionConfiguration,
        urlSessionDelegate: URLSessionDelegate?
    ) {
        var request = request
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = TimeInterval(INT_MAX)
        request.setValue(lastEventId, forHTTPHeaderField: "Last-Event-Id")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        self.configuration = urlSessionConfiguration
        self.request = request
        self.dataTaskDelegate.urlSessionDelegate = urlSessionDelegate
        setupDataTaskDelegate()
    }

    deinit {
        onReceive = nil
        onComplete = nil
        close()
    }

    // MARK: - Private methods

    private func open() {
        close()
        urlSession = URLSession(
            configuration: configuration,
            delegate: dataTaskDelegate,
            delegateQueue: nil
        )
        urlSession?.dataTask(with: request).resume()
    }

    private func close() {
        urlSession?.invalidateAndCancel()
    }

    private func setupDataTaskDelegate() {
        dataTaskDelegate.onReceive = { [weak self] data in
            guard let self = self else { return }
            for event in self.parser.events(from: data) {
                self.onReceive?(event)
            }
        }

        dataTaskDelegate.onComplete = { [weak self] response, error in
            self?.close()
            self?.onComplete?(response, error)
        }
    }
}

// MARK: - Errors

struct EventSourceError: Error {
    let response: HTTPURLResponse?
    let dataStreamError: Error?
}

// MARK: - URLSessionDataDelegate

private final class DataTaskDelegate: NSObject, URLSessionDataDelegate {
    weak var urlSessionDelegate: URLSessionDelegate?
    var onReceive: ((Data) -> Void)?
    var onComplete: ((HTTPURLResponse?, Error?) -> Void)?
    private var dataDelegate: URLSessionDataDelegate? { urlSessionDelegate as? URLSessionDataDelegate }

    deinit {
        onReceive = nil
        onComplete = nil
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        onReceive?(data)
        dataDelegate?.urlSession?(
            session,
            dataTask: dataTask,
            didReceive: data
        )
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if task.state == .completed {
            onComplete?(task.response as? HTTPURLResponse, error)
        }
        dataDelegate?.urlSession?(
            session,
            task: task,
            didCompleteWithError: error
        )
    }

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        urlSessionDelegate?.urlSession?(session, didBecomeInvalidWithError: error)
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if urlSessionDelegate?.responds(to: #selector(urlSession(_:didReceive:completionHandler:))) == true {
            urlSessionDelegate?.urlSession?(
                session,
                didReceive: challenge,
                completionHandler: completionHandler
            )
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
