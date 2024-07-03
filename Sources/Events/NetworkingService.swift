
import Foundation

protocol NetworkingServiceProtocol {
    func sendEvents(_ events: [Event]) async throws -> Bool
}


class NetworkingService: NetworkingServiceProtocol {
    private let session: URLSession
    private let projectId: String
    private let sdkType: String
    private let sdkVersion: String
    private let apiURL = URL(string: "https://pulse.walletconnect.com/batch")!

    init(session: URLSession = .shared, projectId: String, sdkType: String, sdkVersion: String) {
        self.session = session
        self.projectId = projectId
        self.sdkType = sdkType
        self.sdkVersion = sdkVersion
    }

    func sendEvents(_ events: [Event]) async throws -> Bool {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(projectId, forHTTPHeaderField: "x-project-id")
        request.setValue(sdkType, forHTTPHeaderField: "x-sdk-type")
        request.setValue(sdkVersion, forHTTPHeaderField: "x-sdk-version")

        request.httpBody = try JSONEncoder().encode(events)

        return try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    continuation.resume(returning: false)
                    return
                }

                continuation.resume(returning: true)
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

    func sendEvents(_ events: [Event]) async throws -> Bool {
        attemptCount += 1
        if shouldFail {
            throw NSError(domain: "MockError", code: -1, userInfo: nil)
        }
        return true
    }
}
#endif
