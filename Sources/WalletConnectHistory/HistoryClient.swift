import Foundation

final class HistoryClient {

    private let clientIdStorage: ClientIdStorage

    init(clientIdStorage: ClientIdStorage) {
        self.clientIdStorage = clientIdStorage
    }

    func registerTags(payload: RegisterPayload, historyUrl: String) async throws {
        let service = HTTPNetworkClient(host: historyUrl)
        let api = HistoryAPI.register(payload: payload, jwt: try getJwt(historyUrl: historyUrl))
        try await service.request(service: api)
    }

    func getMessages(payload: GetMessagesPayload, historyUrl: String) async throws -> GetMessagesResponse {
        let service = HTTPNetworkClient(host: historyUrl)
        let api = HistoryAPI.messages(payload: payload)
        return try await service.request(GetMessagesResponse.self, at: api)
    }
}

private extension HistoryClient {

    func getJwt(historyUrl: String) throws -> String {
        let authenticator = ClientIdAuthenticator(clientIdStorage: clientIdStorage, url: historyUrl)
        return try authenticator.createAuthToken()
    }
}
