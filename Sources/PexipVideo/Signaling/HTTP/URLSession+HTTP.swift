import Foundation

extension URLSession {
    func data(
        for request: URLRequest,
        validate: Bool,
        logger: CategoryLogger? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        var request = request
        request.setHTTPHeader(.defaultUserAgent)

        let requestName = request.methodWithDescription

        do {
            logger?.debug("\(requestName) requested...")

            let (data, response) = try await data(for: request)

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

    func json<T: Decodable>(
        for request: URLRequest,
        validate: Bool,
        decoder: JSONDecoder,
        logger: CategoryLogger? = nil
    ) async throws -> T {
        let (data, _) = try await data(for: request, validate: validate)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            logger?.error(
                "Failed decoding data for \(request.methodWithDescription)"
            )
            throw error
        }
    }

    // MARK: - Private

    @available(iOS, deprecated: 15.0, message: "Use the built-in API instead")
    private func data(for request: URLRequest) async throws -> (Data, URLResponse) {
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
