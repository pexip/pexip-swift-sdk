import Foundation

/// Implementation of the W3C SSE spec
/// https://html.spec.whatwg.org/multipage/server-sent-events.html
final class EventSource: NSObject, URLSessionDataDelegate {
    typealias EventListener = (Data?) -> Void
    
    enum State {
        case connecting
        case open
        case closed
    }
    
    let url: URL
    var onOpen: (() -> Void)?
    var onMessage: ((MessageEvent) -> Void)?
    var onComplete: ((HTTPURLResponse?, Error?) -> Void)?
    
    private(set) var state: State = .closed
    private(set) var lastEventId: String?
    private(set) var reconnectionTime: TimeInterval = 3
    
    private let headers: () -> [HTTPHeader]
    private let protocolClasses: [AnyClass]
    private let parser = EventStreamParser()
    private var urlSession: URLSession?
    private var eventListeners = [String: EventListener]()
    
    // MARK: - Init
    
    init(
        url: URL,
        headers: @escaping () -> [HTTPHeader],
        protocolClasses: [AnyClass] = []
    ) {
        self.url = url
        self.protocolClasses = protocolClasses
        self.headers = headers
        super.init()
    }
    
    // MARK: - API

    func connect(lastEventId: String? = nil) {
        self.lastEventId = lastEventId
                
        if state == .open {
            disconnect()
        }
        
        state = .connecting
        
        let configuration = URLSessionConfiguration.eventSourceDefault
        configuration.protocolClasses = protocolClasses
        
        urlSession = URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
        
        urlSession?.dataTask(with: makeUrlRequest()).resume()
    }
    
    func reconnect() {
        Task {
            try await Task.sleep(seconds: reconnectionTime)
            connect()
        }
    }

    func disconnect() {
        state = .closed
        urlSession?.invalidateAndCancel()
        parser.clear()
    }

    func addEventListener(_ event: String, handler: @escaping EventListener) {
        eventListeners[event] = handler
    }

    func removeEventListener(_ event: String) {
        eventListeners.removeValue(forKey: event)
    }
    
    // MARK: - URLSessionDataDelegate

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let events = parser.events(from: data)
        notifyEventListeners(events)
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        completionHandler(.allow)
        state = .open
        onOpen?()
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if (error as NSError?)?.code != NSURLErrorCancelled {
            disconnect()
            onComplete?(task.response as? HTTPURLResponse, error)
        }
    }
    
    // MARK: - Private methods

    private func makeUrlRequest() -> URLRequest {
        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData
        )
        request.timeoutInterval = TimeInterval(INT_MAX)
        request.setValue(lastEventId, forHTTPHeaderField: "Last-Event-Id")
        headers().forEach { request.setHTTPHeader($0) }
        return request
    }
    
    private func notifyEventListeners(_ events: [MessageEvent]) {
        for event in events {
            lastEventId = event.id

            if let reconnectionTime = event.reconnectionTime {
                self.reconnectionTime = reconnectionTime
            }
            
            if let name = event.name, let eventListener = eventListeners[name] {
                eventListener(event.data?.data(using: .utf8))
            }
            
            onMessage?(event)
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

