import Foundation
import PexipCore

struct HTTPClient {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let logger: Logger?

    // MARK: - Init

    init(
        session: URLSession,
        decoder: JSONDecoder = .init(),
        logger: Logger? = nil
    ) {
        self.session = session
        self.decoder = decoder
        self.logger = logger
    }

    // MARK: - Internal methods

    func data(
        for request: URLRequest,
        validate: Bool = true
    ) async throws -> (Data, HTTPURLResponse) {
        let request = request.withUserAgentHeader()
        let requestName = request.methodWithDescription

        do {
            logger?.debug("\(requestName) requested...")

            let (data, response) = try await session.data(for: request)

            guard let response = response as? HTTPURLResponse else {
                throw HTTPError.invalidHTTPResponse
            }

            logger?.debug(
                "\(requestName) received server response, status: \(response.statusCode)"
            )

            if validate {
                try response.validate(for: request)
            }

            return (data, response)
        } catch {
            logger?.error("\(requestName) failed with error: \(error)")
            throw error
        }
    }

    func json<T>(
        for request: URLRequest,
        validate: Bool = true
    ) async throws -> T where T: Decodable, T: Hashable {
        let (data, _) = try await data(for: request, validate: validate)

        do {
            return try decoder.decode(
                ResponseContainer<T>.self,
                from: data
            ).result
        } catch {
            logger?.error(
                "Failed decoding data for \(request.methodWithDescription)"
            )
            throw error
        }
    }

    func eventSource<T>(
        withRequest request: URLRequest,
        lastEventId: String? = nil,
        transform: @escaping (HTTPEvent) -> T?
    ) -> AsyncThrowingStream<T, Error> {
        session.eventSource(
            withRequest: request.withUserAgentHeader(),
            lastEventId: lastEventId,
            transform: transform
        )
    }
}

// MARK: - Private extensions

private extension URLSession {
    @available(iOS, deprecated: 15.0, message: "Use the built-in API instead")
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: request) { data, response, error in
                guard let data = data, let response = response else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }

                continuation.resume(returning: (data, response))
            }

            task.resume()
        }
    }
}

private extension URLRequest {
    func withUserAgentHeader() -> URLRequest {
        var request = self
        request.setHTTPHeader(.defaultUserAgent)
        return request
    }
}
