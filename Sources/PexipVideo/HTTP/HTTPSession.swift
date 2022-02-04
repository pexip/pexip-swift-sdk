import Foundation

final class HTTPSession {
    private let session: URLSession
    private let logger: CategoryLogger

    // MARK: - Init

    init(
        protocolClasses: [AnyClass] = [],
        timeoutIntervalForRequest: TimeInterval = 10,
        logger: CategoryLogger
    ) {
        let configuration: URLSessionConfiguration = .ephemeral
        configuration.timeoutIntervalForRequest = timeoutIntervalForRequest
        configuration.protocolClasses = protocolClasses

        self.session = URLSession(configuration: configuration)
        self.logger = logger
    }

    // MARK: - Internal methods

    func data(
        for request: URLRequest,
        validate: Bool = true
    ) async throws -> (Data, HTTPURLResponse) {
        do {
            logger.debug("\(request.name) requested...")

            let (data, response) = try await session.data(for: request)

            guard let response = response as? HTTPURLResponse else {
                throw HTTPError.invalidHTTPResponse
            }

            logger.debug(
                "\(request.name) received server response, status: \(response.statusCode)"
            )

            if validate {
                try response.validate(for: request)
            }

            return (data, response)
        } catch {
            logger.error("\(request.name) failed with error: \(error)")
            throw error
        }
    }

    func json<T: Decodable>(
        for request: URLRequest,
        decoder: JSONDecoder = .init(),
        validate: Bool = true
    ) async throws -> T {
        let (data, _) = try await data(for: request, validate: validate)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            logger.error("Failed decoding data for \(request.name)")
            throw error
        }
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
    var name: String {
        return "\(httpMethod ?? "(Invalid method)") \(description)"
    }
}
