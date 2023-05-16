import Foundation

struct Endpoint {
    let path: String
    let queryItems: [URLQueryItem]
    let headers: [Headers]
    let method: Method
    let host: String
    let body: Data?
    let validResponseCodes: Set<Int>

    public enum Method: String {
        case GET
        case POST
        case PUT
        case PATCH
        case DELETE
    }

    enum Headers {
        /// Standard headers used for every network call
        case standard

        public var makeHeader: [String: String] {
            switch self {
            case .standard:
                return [
                    "Content-Type": "application/json",
                ]
            }
        }
    }

    var urlRequest: URLRequest {
        var urlRequest = URLRequest(url: urlForRequest)
        urlRequest.httpMethod = method.rawValue
        urlRequest.httpBody = body
        urlRequest.allHTTPHeaderFields = makeHTTPHeaders(headers)
        return urlRequest
    }

    private var urlForRequest: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard
            let url = components.url
        else {
            preconditionFailure(
                """
                Failed to construct valid url, if setting up new endpoint
                make sure you have prefix / in path such as /v1/users
                """
            )
        }

        return url
    }

    private func makeHTTPHeaders(_ headers: [Headers]) -> [String: String] {
        headers.reduce(into: [String: String]()) { result, nextElement in
            result = result.merging(nextElement.makeHeader) { _, new in new }
        }
    }
}

extension Endpoint.Headers: Equatable {
    static func == (lhs: Endpoint.Headers, rhs: Endpoint.Headers) -> Bool {
        lhs.makeHeader == rhs.makeHeader
    }
}

extension Endpoint {
    
    /// Un-authenticated endpoint.
    /// - Parameters:
    ///   - path: Path for your endpoint`
    ///   - headers: Specific headers
    ///   - method: .GET, .POST etc
    ///   - host: Host url
    ///   - shouldEncodePath: This setting affects how your url is constructed.
    ///   - body: If you need to pass parameters, provide them here.
    ///   - validResponseCodes: This is set to default value `Set(200 ..< 300)`
    ///   and can be overridden if needed
    /// - Returns: Endpoint with URLRequest that gets passed directly to HttpService.
    static func bare(
        path: String,
        queryItems: [URLQueryItem] = [],
        headers: [Endpoint.Headers] = [],
        method: Endpoint.Method,
        host: String,
        body: Data? = nil,
        validResponseCodes: Set<Int> = Set(200 ..< 300)
    ) -> Self {
        var headers = headers
        headers.append(.standard)
        return Self(
            path: path,
            queryItems: queryItems,
            headers: headers,
            method: method,
            host: host,
            body: body,
            validResponseCodes: validResponseCodes
        )
    }
}
