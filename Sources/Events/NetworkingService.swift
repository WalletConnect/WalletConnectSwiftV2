import Foundation

protocol NetworkingServiceProtocol {
    func sendEvents<T: Encodable>(_ events: [T]) async throws -> Bool
}

class NetworkingService: NetworkingServiceProtocol {
    private let session: URLSession
    private let projectId: String
    private let sdkVersion: String
    private let apiURL = URL(string: "https://pulse.walletconnect.com/batch")!

    init(session: URLSession = .shared, projectId: String, sdkVersion: String) {
        self.session = session
        self.projectId = projectId
        self.sdkVersion = sdkVersion
    }

    func sendEvents<T: Encodable>(_ events: [T]) async throws -> Bool {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(projectId, forHTTPHeaderField: "x-project-id")
        request.setValue("events_sdk", forHTTPHeaderField: "x-sdk-type")
        request.setValue(sdkVersion, forHTTPHeaderField: "x-sdk-version")

        request.httpBody = try JSONEncoder().encode(events)

        return try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                if let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) {
                    continuation.resume(returning: true)
                } else {
                    continuation.resume(returning: false)
                }
            }

            task.priority = URLSessionTask.lowPriority
            task.resume()
        }
    }
}

#if DEBUG
class MockNetworkingService: NetworkingServiceProtocol {
    var shouldFail = false
    var attemptCount = 0

    func sendEvents<T>(_ events: [T]) async throws -> Bool where T : Encodable {
        attemptCount += 1
        if shouldFail {
            throw NSError(domain: "MockError", code: -1, userInfo: nil)
        }
        return true
    }
}
#endif
