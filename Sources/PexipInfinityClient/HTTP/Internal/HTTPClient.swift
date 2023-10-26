//
// Copyright 2022-2023 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
        validate: Bool = true,
        fileID: StaticString = #fileID,
        function: StaticString = #function
    ) async throws -> (Data, HTTPURLResponse) {
        let request = request.withUserAgentHeader()
        let callerName = self.callerName(fileID: fileID, function: function)

        do {
            logger?.debug("\(callerName) requested...")

            let (data, response) = try await session.data(for: request)

            guard let response = response as? HTTPURLResponse else {
                throw HTTPError.invalidHTTPResponse
            }

            logger?.debug(
                "\(callerName) received server response, status: \(response.statusCode)"
            )

            if validate {
                try response.validate(for: request)
            }

            return (data, response)
        } catch {
            logger?.error("\(callerName) failed with error: \(error)")
            throw error
        }
    }

    func json<T>(
        for request: URLRequest,
        validate: Bool = true,
        fileID: StaticString = #fileID,
        function: StaticString = #function
    ) async throws -> T where T: Decodable, T: Hashable {
        let (data, _) = try await data(
            for: request,
            validate: validate,
            fileID: fileID,
            function: function
        )

        do {
            return try decoder.decode(
                ResponseContainer<T>.self,
                from: data
            ).result
        } catch {
            let callerName = self.callerName(fileID: fileID, function: function)
            logger?.error(
                "Failed decoding data for \(callerName)"
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

    func callerName(
        fileID: StaticString,
        function: StaticString
    ) -> String {
        var name = ""

        if let url = URL(string: fileID.description) {
            let typeName = url.deletingPathExtension().lastPathComponent
            name = typeName + "."
        }

        if let function = function.description.components(separatedBy: "(").first {
            name = "\(name)\(function)"
        }

        return name
    }
}

// MARK: - Private extensions

private extension URLRequest {
    func withUserAgentHeader() -> URLRequest {
        var request = self
        request.setHTTPHeader(.defaultUserAgent)
        return request
    }
}
