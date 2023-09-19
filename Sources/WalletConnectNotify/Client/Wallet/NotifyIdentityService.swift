import Foundation

final class NotifyIdentityService {

    private let keyserverURL: URL
    private let identityClient: IdentityClient
    private let logger: ConsoleLogging

    init(keyserverURL: URL, identityClient: IdentityClient, logger: ConsoleLogging) {
        self.keyserverURL = keyserverURL
        self.identityClient = identityClient
        self.logger = logger
    }

    public func register(account: Account, domain: String, isLimited: Bool, onSign: @escaping SigningCallback) async throws {
        let statement = makeStatement(isLimited: isLimited, domain: domain, keyserverHost: keyserverURL.host!)
        let pubKey = try await identityClient.register(account: account,
            domain: domain,
            statement: statement,
            resources: [keyserverURL.absoluteString],
            onSign: onSign)
        logger.debug("Did register an account: \(account)")
    }

    func isIdentityRegistered(account: Account) -> Bool {
        return identityClient.isIdentityRegistered(account: account)
    }
}

private extension NotifyIdentityService {

    func makeStatement(isLimited: Bool, domain: String, keyserverHost: String) -> String {
        switch isLimited {
        case true:
            return "I further authorize this DAPP to send and receive messages on my behalf for this domain and manage my identity at \(keyserverHost)."
        case false:
            return "I further authorize this WALLET to send and receive messages on my behalf for ALL domains and manage my identity at \(keyserverHost)."
        }
    }
}
