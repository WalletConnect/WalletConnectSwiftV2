import Foundation

struct HttpService {
    var performRequest: (_ endpoint: Endpoint) async throws -> Result<Data, Error>
}

extension HttpService {
    
    static var live: Self = .init(performRequest: { endpoint in
        
        let (data, response) = try await URLSession.shared.data(for: endpoint.urlRequest)
        
        let error = errorForResponse(response, data, validResponseCodes: endpoint.validResponseCodes)
        if let error = error {
            return .failure(error)
        } else {
            return .success(data)
        }
    })
    
    private static func errorForResponse(
        _ response: URLResponse?,
        _ data: Data?, validResponseCodes: Set<Int>
    ) -> Error? {
        guard let httpResponse = response as? HTTPURLResponse else {
            return nil
        }

        if !validResponseCodes.contains(httpResponse.statusCode) {
            return Errors.badResponseCode(
                code: httpResponse.statusCode,
                payload: data
            )
        }

        return nil
    }
    
    enum Errors: Error, Equatable {
        case emptyResponse
        case badResponseCode(code: Int, payload: Data?)
        
        public var properties: [String: String] {
            switch self {
            case let .badResponseCode(code, _):
                return [
                    "category": "http_error",
                    "http_code": "\(String(code))"
                ]
            case .emptyResponse:
                return [
                    "category": "payload",
                    "message": "Failed for empty response"
                ]
            }
        }
    }
}
