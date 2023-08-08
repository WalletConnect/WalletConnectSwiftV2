import Foundation

public actor HTTPNetworkClient: HTTPClient {

    let host: String

    private let session: URLSession

    public init(host: String, session: URLSession = .shared) {
        self.host = host
        self.session = session
    }

    public func request<T: Decodable>(_ type: T.Type, at service: HTTPService) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            request(T.self, at: service) { result in
                do {
                    let value = try result.get()
                    continuation.resume(returning: value)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func request(service: HTTPService) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            request(service: service) { result in
                continuation.resume(with: result)
            }
        }
    }

    private func request<T: Decodable>(_ type: T.Type, at service: HTTPService, completion: @escaping (Result<T, Error>) -> Void) {
        guard let request = service.resolve(for: host) else {
            completion(.failure(HTTPError.malformedURL(service)))
            return
        }
        session.dataTask(with: request) { data, response, error in
            do {
                try HTTPNetworkClient.validate(response, error)
                guard let validData = data else {
                    throw HTTPError.responseDataNil
                }
                let decoded = try JSONDecoder().decode(T.self, from: validData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func request(service: HTTPService, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let request = service.resolve(for: host) else {
            completion(.failure(HTTPError.malformedURL(service)))
            return
        }
        session.dataTask(with: request) { data, response, error in
            do {
                try HTTPNetworkClient.validate(response, error)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private static func validate(_ urlResponse: URLResponse?, _ error: Error?) throws {
        if let error = error {
            throw HTTPError.dataTaskError(error)
        }
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw HTTPError.noResponse
        }
        guard (200..<300) ~= httpResponse.statusCode else {
            throw HTTPError.badStatusCode(httpResponse.statusCode)
        }
    }
}
