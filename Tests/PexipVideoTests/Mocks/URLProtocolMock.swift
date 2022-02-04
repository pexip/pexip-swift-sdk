import XCTest

final class URLProtocolMock: URLProtocol {
    struct Response {
        let statusCode: Int
        let data: Data
    }

    static var makeResponse: (URLRequest) throws -> Response = { _ in
        Response(statusCode: 200, data: Data())
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
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
                    headerFields: nil
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
