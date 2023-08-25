import Foundation

protocol PushAuthenticating {
    func createAuthToken() throws -> String
}

class PushAuthenticator: PushAuthenticating {
    private let clientIdStorage: ClientIdStoring
    private let pushHost: String

    init(clientIdStorage: ClientIdStoring, pushHost: String) {
        self.clientIdStorage = clientIdStorage
        self.pushHost = pushHost
    }

    func createAuthToken() throws -> String {
        let keyPair = try clientIdStorage.getOrCreateKeyPair()
        let payload = PushAuthPayload(subject: getSubject(), audience: getAudience())
        return try payload.signAndCreateWrapper(keyPair: keyPair).jwtString
    }

    private func getAudience() -> String {
        return "https://\(pushHost)"
    }

    private func getSubject() -> String {
        return Data.randomBytes(count: 32).toHexString()
    }
}

