import Foundation

struct Endpoint {
    let path: String
    let queryParameters: [URLQueryItem]
}

actor HTTPClient {

    let host: String

    private let session: URLSession

    init(host: String, session: URLSession = .shared) {
        self.host = host
        self.session = session
    }

    func request<T: Decodable>(_ type: T.Type, at endpoint: Endpoint) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            request(T.self, at: endpoint) { response in
                do { 
                    let value = try response.result.get()
                    continuation.resume(returning: value)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func request<T: Decodable>(_ type: T.Type, at endpoint: Endpoint, completion: @escaping (HTTPResponse<T>) -> Void) {
        let request = makeRequest(for: endpoint)
        session.dataTask(with: request) { data, response, error in
            completion(HTTPResponse(request: request, data: data, response: response, error: error))
        }.resume()
    }

    private func makeRequest(for endpoint: Endpoint) -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = endpoint.path
        components.queryItems = endpoint.queryParameters
        guard let url = components.url else {
            fatalError() // TODO: Remove fatal error when url fails to build
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return request
    }
}
