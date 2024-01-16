import Foundation

public protocol ClientIdAuthenticating {
    func createAuthToken(url: String) throws -> String
}

public final class ClientIdAuthenticator: ClientIdAuthenticating {
    private let clientIdStorage: ClientIdStoring

    public init(clientIdStorage: ClientIdStoring) {
        self.clientIdStorage = clientIdStorage
    }

    public func createAuthToken(url: String) throws -> String {
        let keyPair = try clientIdStorage.getOrCreateKeyPair()
        let payload = RelayAuthPayload(subject: getSubject(), audience: url)
        return try payload.signAndCreateWrapper(keyPair: keyPair).jwtString
    }

    private func getSubject() -> String {
        return Data.randomBytes(count: 32).toHexString()
    }
}
