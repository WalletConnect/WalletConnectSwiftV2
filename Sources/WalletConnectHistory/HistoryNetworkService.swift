import Foundation

final class HistoryNetworkService {

    private let clientIdStorage: ClientIdStorage

    init(clientIdStorage: ClientIdStorage) {
        self.clientIdStorage = clientIdStorage
    }

    func registerTags(payload: RegisterPayload, historyUrl: String) async throws {
        let service = HTTPNetworkClient(host: try host(from: historyUrl))
        let api = HistoryAPI.register(payload: payload, jwt: try getJwt(historyUrl: historyUrl))
        try await service.request(service: api)
    }

    func getMessages(payload: GetMessagesPayload, historyUrl: String) async throws -> GetMessagesResponse {
        let service = HTTPNetworkClient(host: try host(from: historyUrl))
        let api = HistoryAPI.messages(payload: payload)
        return try await service.request(GetMessagesResponse.self, at: api)
    }
}

private extension HistoryNetworkService {

    enum Errors: Error {
        case couldNotResolveHost
    }

    func getJwt(historyUrl: String) throws -> String {
        let authenticator = ClientIdAuthenticator(clientIdStorage: clientIdStorage, url: historyUrl)
        return try authenticator.createAuthToken()
    }

    func host(from url: String) throws -> String {
        guard let host = URL(string: url)?.host else {
            throw Errors.couldNotResolveHost
        }
        return host
    }
}
