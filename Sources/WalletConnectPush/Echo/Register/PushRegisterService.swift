import Foundation
import WalletConnectNetworking

actor PushRegisterService {
    private let networkInteractor: NetworkInteracting
    private let httpClient: HTTPClient

    enum Errors: Error {
        case registrationFailed
    }

    init(networkInteractor: NetworkInteracting, httpClient: HTTPClient) {
        self.networkInteractor = networkInteractor
        self.httpClient = httpClient
    }

    func register(deviceToken: Data) async throws {
        let clientId = try networkInteractor.getClientId()
        let token = deviceToken.toHexString()
        let response = try await httpClient.request(
            EchoResponse.self,
            at: EchoAPI.register(clientId: clientId, token: token)
        )
        guard response.status == .ok else {
            throw Errors.registrationFailed
        }
    }
}
