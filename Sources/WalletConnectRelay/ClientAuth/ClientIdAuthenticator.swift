import Foundation

public protocol ClientIdAuthenticating {
    func createAuthToken(url: String?) throws -> String
}

public struct ClientIdAuthenticator: ClientIdAuthenticating {
    private let clientIdStorage: ClientIdStoring
    private let url: String

    public init(clientIdStorage: ClientIdStoring, url: String) {
        self.clientIdStorage = clientIdStorage
        self.url = url
    }

    public func createAuthToken(url: String? = nil) throws -> String {
        let keyPair = try clientIdStorage.getOrCreateKeyPair()
        let payload = RelayAuthPayload(subject: getSubject(), audience: url ?? self.url)
        return try payload.signAndCreateWrapper(keyPair: keyPair).jwtString
    }

    private func getSubject() -> String {
        return Data.randomBytes(count: 32).toHexString()
    }
}
