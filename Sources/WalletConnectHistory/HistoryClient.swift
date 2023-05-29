import Foundation

public final class HistoryClient {

    private let clientIdStorage: ClientIdStorage

    public init(clientIdStorage: ClientIdStorage) {
        self.clientIdStorage = clientIdStorage
    }

    public func registerTags(payload: RegisterPayload, historyUrl: String) async throws {
        guard let host = URL(string: historyUrl)?.host else {
            throw Errors.couldNotResolveHost
        }
        let service = HTTPNetworkClient(host: host)
        let api = HistoryAPI.register(payload: payload, jwt: try getJwt(historyUrl: historyUrl))
        try await service.request(service: api)
    }

    public func getMessages(payload: GetMessagesPayload, historyUrl: String) async throws -> GetMessagesResponse {
        let service = HTTPNetworkClient(host: historyUrl)
        let api = HistoryAPI.messages(payload: payload)
        return try await service.request(GetMessagesResponse.self, at: api)
    }
}

private extension HistoryClient {

    enum Errors: Error {
        case couldNotResolveHost
    }

    func getJwt(historyUrl: String) throws -> String {
        let authenticator = ClientIdAuthenticator(clientIdStorage: clientIdStorage, url: historyUrl)
        return try authenticator.createAuthToken()
    }
}
