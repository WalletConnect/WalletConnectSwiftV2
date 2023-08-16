import Foundation
@testable import HTTPClient

public final class HTTPClientMock<T: Decodable>: HTTPClient {
    private let object: T

    public init(object: T) {
        self.object = object
    }

    public func request<T>(_ type: T.Type, at service: HTTPService) async throws -> T where T: Decodable {
        return object as! T
    }

    public func request(service: HTTPService) async throws {

    }
    
    public func updateHost(host: String) async {
        
    }
}
