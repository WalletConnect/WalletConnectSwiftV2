import Foundation
import WalletConnectNetworking

actor EchoRegisterService {
    private let httpClient: HTTPClient
    private let tenantId: String
    private let clientId: String

    enum Errors: Error {
        case registrationFailed
    }

    init(httpClient: HTTPClient, tenantId: String, clientId: String) {
        self.httpClient = httpClient
        self.clientId = clientId
        self.tenantId = tenantId
    }

    func register(deviceToken: Data) async throws {
        let token = deviceToken.toHexString()
        let response = try await httpClient.request(
            EchoResponse.self,
            at: EchoAPI.register(clientId: clientId, token: token, tenantId: tenantId)
        )
        guard response.status == .ok else {
            throw Errors.registrationFailed
        }
    }
}
