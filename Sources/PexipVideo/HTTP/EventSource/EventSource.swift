import Foundation

/// Implementation of the W3C SSE spec
/// https://html.spec.whatwg.org/multipage/server-sent-events.html
final class EventSource {
    static func eventStream(
        withRequest request: URLRequest,
        lastEventId: String? = nil,
        urlProtocolClasses: [AnyClass]
    ) -> AsyncThrowingStream<MessageEvent, Error> {
        AsyncThrowingStream { continuation in
             let eventSource = EventSource(
                request: request,
                lastEventId: lastEventId,
                urlProtocolClasses: urlProtocolClasses
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
    
    private init(
        request: URLRequest,
        lastEventId: String? = nil,
        urlProtocolClasses: [AnyClass]
    ) {
        configuration = URLSessionConfiguration.eventSourceDefault
        configuration.protocolClasses = urlProtocolClasses
        
        var request = request
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = TimeInterval(INT_MAX)
        request.setValue(lastEventId, forHTTPHeaderField: "Last-Event-Id")
        
        self.request = request
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
    var onReceive: ((Data) -> Void)?
    var onComplete: ((HTTPURLResponse?, Error?) -> Void)?
    
    deinit {
        onReceive = nil
        onComplete = nil
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        onReceive?(data)
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if task.state == .completed {
            onComplete?(task.response as? HTTPURLResponse, error)
        }
    }
}

// MARK: - Private extensions

private extension URLSessionConfiguration {
    static var eventSourceDefault: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = TimeInterval(INT_MAX)
        configuration.timeoutIntervalForResource = TimeInterval(INT_MAX)
        configuration.httpAdditionalHeaders = [
            "Accept": "text/event-stream",
            "Cache-Control": "no-cache"
        ]
        return configuration
    }
}
