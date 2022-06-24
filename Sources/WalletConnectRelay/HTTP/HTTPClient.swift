import Foundation

final class HTTPClient {

    let host: String

    private let session: URLSession

    init(host: String, session: URLSession = .shared) {
        self.host = host
        self.session = session
    }

    func request<T: Decodable>(_ endpoint: Endpoint, completion: @escaping (HTTPResponse<T>) -> Void) {
        let request = makeRequest(for: endpoint)
        session.dataTask(with: request) { data, response, error in
            completion(HTTPResponse(request: request, data: data, response: response, error: error))
        }.resume()
    }

    func makeRequest(for endpoint: Endpoint) -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = endpoint.path
        components.queryItems = []
        guard let url = components.url else {
            fatalError()
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return request
    }
}

enum HTTPError: Error {
    case dataTaskError(Error)
    case noResponse
    case badStatusCode(Int)
    case responseDataNil
    case jsonDecodeFailed(Error, Data)
}

struct HTTPResponse<T: Decodable> {

    let request: URLRequest?
    let data: Data?
    let urlResponse: HTTPURLResponse?
    let result: Result<T, Error>

    init(request: URLRequest? = nil, data: Data? = nil, response: URLResponse? = nil, error: Error? = nil) {
        self.data = data
        self.request = request
        self.urlResponse = response as? HTTPURLResponse
        self.result = Self.validate(data, response, error).flatMap { data -> Result<T, Error> in
            if let rawData = data as? T {
                return .success(rawData)
            }
            return Self.decode(data)
        }
    }
}

extension HTTPResponse {

    private static func validate(_ data: Data?, _ urlResponse: URLResponse?, _ error: Error?) -> Result<Data, Error> {
        if let error = error {
            return .failure(HTTPError.dataTaskError(error))
        }
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            return .failure(HTTPError.noResponse)
        }
        guard (200..<300) ~= httpResponse.statusCode else {
            return .failure(HTTPError.badStatusCode(httpResponse.statusCode))
        }
        guard let validData = data else {
            return .failure(HTTPError.responseDataNil)
        }
        return .success(validData)
    }

    private static func decode<T: Decodable>(_ data: Data) -> Result<T, Error> {
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return .success(decoded)
        } catch let jsonError {
            return .failure(HTTPError.jsonDecodeFailed(jsonError, data))
        }
    }
}
