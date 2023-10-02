import Foundation

public protocol ClientIdAuthenticating {
    func createAuthToken(url: String?) throws -> String
}

public final class ClientIdAuthenticator: ClientIdAuthenticating {
    private let clientIdStorage: ClientIdStoring
    private var url: String

    public init(clientIdStorage: ClientIdStoring, url: String) {
        self.clientIdStorage = clientIdStorage
        self.url = url
    }

    public func createAuthToken(url: String? = nil) throws -> String {
        url.flatMap { self.url = $0 }
        
        let keyPair = try clientIdStorage.getOrCreateKeyPair()
        let payload = RelayAuthPayload(subject: getSubject(), audience: self.url)
        return try payload.signAndCreateWrapper(keyPair: keyPair).jwtString
    }

    private func getSubject() -> String {
        return Data.randomBytes(count: 32).toHexString()
    }
}
