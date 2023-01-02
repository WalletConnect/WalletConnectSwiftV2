import Foundation
import WalletConnectNetworking

actor EchoRegisterService {
    private let httpClient: HTTPClient
    private let projectId: String
    private let clientId: String

    enum Errors: Error {
        case registrationFailed
    }

    init(httpClient: HTTPClient, projectId: String, clientId: String) {
        self.httpClient = httpClient
        self.clientId = clientId
        self.projectId = projectId
    }

    func register(deviceToken: Data) async throws {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        let response = try await httpClient.request(
            EchoResponse.self,
            at: EchoAPI.register(clientId: clientId, token: token, projectId: projectId)
        )
        guard response.status == .ok else {
            throw Errors.registrationFailed
        }
    }
}
