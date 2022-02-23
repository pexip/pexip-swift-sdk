import XCTest

final class URLProtocolMock: URLProtocol {
    struct Response {
        let statusCode: Int
        let data: Data
        var headerFields: [String: String]?
    }

    static var makeResponse: (URLRequest) throws -> Response = { _ in
        Response(statusCode: 200, data: Data())
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
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
            let response = try URLProtocolMock.makeResponse(request)
            let httpResponse = try XCTUnwrap(
                HTTPURLResponse(
                    url: XCTUnwrap(request.url),
                    statusCode: response.statusCode,
                    httpVersion: "HTTP/1.1",
                    headerFields: response.headerFields
                )
            )

            client.urlProtocol(self,
                didReceive: httpResponse,
                cacheStoragePolicy: .notAllowed
            )
            client.urlProtocol(self, didLoad: response.data)
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
