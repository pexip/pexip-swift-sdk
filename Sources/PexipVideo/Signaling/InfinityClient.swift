import Foundation

/// Pexip client REST API v2.
struct InfinityClient {
    static func apiURL(forNode nodeAddress: URL) -> URL {
        nodeAddress.appendingPathComponent("api/client/v2")
    }

    enum Path {
        case conference
        case participant(id: UUID)
        case call(participantId: UUID, callId: UUID)
    }

    enum TokenStrategy {
        case fromStorage
        case value(Token)
        case none
    }

    let decoder = JSONDecoder()
    let logger: LoggerProtocol

    private let nodeAddress: URL
    private let alias: ConferenceAlias
    private let urlSession: URLSession
    private let tokenProvider: TokenProvider?

    // MARK: - Init

    init(
        nodeAddress: URL,
        alias: ConferenceAlias,
        urlSession: URLSession,
        tokenProvider: TokenProvider?,
        logger: LoggerProtocol
    ) {
        self.nodeAddress = nodeAddress
        self.alias = alias
        self.urlSession = urlSession
        self.tokenProvider = tokenProvider
        self.logger = logger
    }

    // MARK: - API URL

    func request(
        withMethod method: HTTPMethod,
        path: Path,
        name: String,
        token tokenStrategy: TokenStrategy = .fromStorage
    ) async throws -> URLRequest {
        var request = URLRequest(
            url: url(for: path).appendingPathComponent(name),
            httpMethod: method
        )
        request.setHTTPHeader(.defaultUserAgent)

        switch tokenStrategy {
        case .fromStorage:
            if let token = try await tokenProvider?.token() {
                setToken(token, to: &request)
            }
        case .value(let token):
            setToken(token, to: &request)
        case .none:
            break
        }

        return request
    }

    // MARK: - Requests

    func data(
        for request: URLRequest,
        validate: Bool = true
    ) async throws -> (Data, HTTPURLResponse) {
        try await urlSession.data(
            for: request,
            validate: validate,
            logger: logger[.http]
        )
    }

    func json<T: Decodable>(
        for request: URLRequest,
        validate: Bool = true
    ) async throws -> T where T: Hashable {
        let object = try await urlSession.json(
            for: request,
            validate: validate,
            decoder: decoder,
            logger: logger[.http]
        ) as ResponseContainer<T>

        return object.result
    }

    func eventStream(
        withRequest request: URLRequest,
        lastEventId: String? = nil
    ) -> AsyncThrowingStream<MessageEvent, Error> {
        EventSource.eventStream(
            withRequest: request,
            lastEventId: lastEventId,
            urlSessionConfiguration: urlSession.configuration,
            // Pass the delegate of the current URLSession to be notified about
            // important network events, such as authentication challenges, etc.
            urlSessionDelegate: urlSession.delegate
        )
    }

    // MARK: - Private methods

    private func url(for path: Path) -> URL {
        switch path {
        case .conference:
            return InfinityClient
                .apiURL(forNode: nodeAddress)
                .appendingPathComponent("conferences/\(alias.uri)")
        case .participant(let id):
            return url(for: .conference)
                .appendingPathComponent("participants")
                .appendingPathComponent(id.uuidString.lowercased())
        case .call(let participantId, let callId):
            return url(for: .participant(id: participantId))
                .appendingPathComponent("calls")
                .appendingPathComponent(callId.uuidString.lowercased())
        }
    }

    private func setToken(_ token: Token, to request: inout URLRequest) {
        request.setHTTPHeader(.init(name: "token", value: token.value))
    }
}
