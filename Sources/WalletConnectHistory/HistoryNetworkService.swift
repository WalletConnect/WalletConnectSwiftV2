import Foundation

final class HistoryNetworkService {

    private let clientIdStorage: ClientIdStorage

    init(clientIdStorage: ClientIdStorage) {
        self.clientIdStorage = clientIdStorage
    }

    func registerTags(payload: RegisterPayload, historyUrl: String) async throws {
        let service = HTTPNetworkClient(host: historyUrl)
        let api = HistoryAPI.register(payload: payload, jwt: try await getJwt())
        try await service.request(service: api)
    }
}

private extension HistoryNetworkService {

    func getJwt() async throws -> String {
        let keyPair = try clientIdStorage.getOrCreateKeyPair()
        let payload = RelayAuthPayload(subject: getSubject(), audience: getAudience())
        return try payload.signAndCreateWrapper(keyPair: keyPair).jwtString
    }
}
