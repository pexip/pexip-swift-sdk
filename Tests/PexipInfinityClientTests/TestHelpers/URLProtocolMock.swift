//
// Copyright 2022-2024 Pexip AS
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

import XCTest

final class URLProtocolMock: URLProtocol {
    enum Response {
        case http(statusCode: Int, data: Data, headers: [String: String]?)
        case url(Data)
        case error(Error)
    }

    static var makeResponse: (URLRequest) throws -> Response = { _ in
        .http(statusCode: 200, data: Data(), headers: nil)
    }

    override static func canInit(with request: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        var request = request
        if let httpBodyStream = request.httpBodyStream {
            let data = Data(reading: httpBodyStream)
            request.httpBodyStream = nil
            request.httpBody = data
        }
        return request
    }

    override func startLoading() {
        guard let client = client else { return }

        do {
            let response: URLResponse
            let responseData: Data

            switch try Self.makeResponse(request) {
            case let .http(statusCode, data, headers):
                response = try XCTUnwrap(
                    HTTPURLResponse(
                        url: XCTUnwrap(request.url),
                        statusCode: statusCode,
                        httpVersion: "HTTP/1.1",
                        headerFields: headers
                    )
                )
                responseData = data
            case .url(let data):
                response = URLResponse()
                responseData = data
            case .error(let error):
                throw error
            }

            client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client.urlProtocol(self, didLoad: responseData)
        } catch {
            client.urlProtocol(self, didFailWithError: error)
        }

        client.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        // no-op.
    }
}

private extension Data {
    init(reading input: InputStream) {
        self.init()
        input.open()

        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        while input.hasBytesAvailable {
            let read = input.read(buffer, maxLength: bufferSize)
            self.append(buffer, count: read)
        }
        buffer.deallocate()

        input.close()
    }
}
