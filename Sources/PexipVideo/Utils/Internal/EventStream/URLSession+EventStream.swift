import Foundation

/// Implementation of the W3C SSE spec
/// https://html.spec.whatwg.org/multipage/server-sent-events.html
extension URLSession {
    struct EventStreamError: Error {
        let response: HTTPURLResponse?
        let dataStreamError: Error?
    }

    /**
     - Parameters:
        - request: URL request for SSE
        - lastEventId: optional last event ID used to reestablish the connection
     */
    func eventStream(
        withRequest request: URLRequest,
        lastEventId: String? = nil
    ) -> AsyncThrowingStream<EventStreamEvent, Error> {
        var request = request
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = TimeInterval(INT_MAX)
        request.setValue(lastEventId, forHTTPHeaderField: "Last-Event-Id")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        return AsyncThrowingStream { continuation in
            let parser = EventStreamParser()
            let dataTaskDelegate = DataTaskDelegate()
            dataTaskDelegate.urlSessionDelegate = delegate

            let urlSession = URLSession(
                // Use a copy of the confuguration object for the current URLSession
                configuration: configuration,
                // Pass the delegate of the current URLSession to be notified about
                // important network events, such as authentication challenges, etc.
                delegate: dataTaskDelegate,
                delegateQueue: nil
            )

            dataTaskDelegate.onReceive = { data in
                for event in parser.events(from: data) {
                    continuation.yield(event)
                }
            }

            dataTaskDelegate.onComplete = { response, error in
                urlSession.invalidateAndCancel()
                continuation.finish(
                   throwing: EventStreamError(
                       response: response,
                       dataStreamError: error
                   )
                )
            }

            continuation.onTermination = { @Sendable _ in
                urlSession.invalidateAndCancel()
            }

            urlSession.dataTask(with: request).resume()
        }
    }
}

// MARK: - URLSessionDataDelegate

private final class DataTaskDelegate: NSObject, URLSessionDataDelegate {
    weak var urlSessionDelegate: URLSessionDelegate?
    var onReceive: ((Data) -> Void)?
    var onComplete: ((HTTPURLResponse?, Error?) -> Void)?
    private var dataDelegate: URLSessionDataDelegate? {
        urlSessionDelegate as? URLSessionDataDelegate
    }

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
