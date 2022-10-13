import Foundation

public protocol HTTPClient {
    func request<T: Decodable>(_ type: T.Type, at service: HTTPService) async throws -> T
    func request(service: HTTPService) async throws
}
