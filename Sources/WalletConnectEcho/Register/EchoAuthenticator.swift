import Foundation

protocol EchoAuthenticating {
    func createAuthToken() throws -> String
}

class EchoAuthenticator: EchoAuthenticating {
    private let clientIdStorage: ClientIdStoring
    private let echoHost: String

    init(clientIdStorage: ClientIdStoring, echoHost: String) {
        self.clientIdStorage = clientIdStorage
        self.echoHost = echoHost
    }

    func createAuthToken() throws -> String {
        let keyPair = try clientIdStorage.getOrCreateKeyPair()
        let payload = EchoAuthPayload(subject: getSubject(), audience: getAudience())
        return try payload.signAndCreateWrapper(keyPair: keyPair).jwtString
    }

    private func getAudience() -> String {
        return "https://\(echoHost)"
    }

    private func getSubject() -> String {
        return Data.randomBytes(count: 32).toHexString()
    }
}

