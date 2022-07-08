import Foundation

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

public protocol HTTPService {
    var scheme: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var body: Data? { get }
    var queryParameters: [String: String]? { get }
    var port: Int? { get }
    func resolve(for host: String) -> URLRequest?
}

public extension HTTPService {

    var scheme: String {
        "http"
    }

    var port: Int? {
        8080
    }

    func resolve(for host: String) -> URLRequest? {
        var components = URLComponents()
        components.scheme = self.scheme
        components.host = host
        components.port = self.port
        components.path = self.path
        if let query = self.queryParameters {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else {
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = self.method.rawValue
        request.httpBody = self.body
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
}
