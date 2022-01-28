import Foundation

 extension URLSession {
     struct HTTP {
         fileprivate let session: URLSession

         func data(
             for request: URLRequest,
             validate: Bool = true
         ) async throws -> (Data, HTTPURLResponse) {
             var request = request
             request.setHTTPHeader(.defaultUserAgent)
             
             let (data, response) = try await session.data(for: request)

             guard let response = response as? HTTPURLResponse else {
                 throw HTTPError.invalidHTTPResponse
             }

             if validate {
                 try response.validate(for: request)
             }

             return (data, response)
         }

         func json<T: Decodable>(
             for request: URLRequest,
             decoder: JSONDecoder = .init(),
             validate: Bool = true
         ) async throws -> T {
             let (data, _) = try await data(for: request, validate: validate)
             return try decoder.decode(T.self, from: data)
         }
     }

     var http: HTTP {
         HTTP(session: self)
     }

     static func ephemeral(
         protocolClasses: [AnyClass] = [],
         timeoutIntervalForRequest: TimeInterval = 10
     ) -> URLSession {
         let configuration: URLSessionConfiguration = .ephemeral
         configuration.timeoutIntervalForRequest = timeoutIntervalForRequest
         configuration.protocolClasses = protocolClasses
         return URLSession(configuration: configuration)
     }

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
