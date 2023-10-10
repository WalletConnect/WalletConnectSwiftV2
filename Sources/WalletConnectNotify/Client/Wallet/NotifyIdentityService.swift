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

    public func register(account: Account, domain: String, onSign: @escaping SigningCallback) async throws {
        let pubKey = try await identityClient.register(account: account,
            domain: domain,
            statement: makeStatement(),
            resources: [keyserverURL.absoluteString],
            onSign: onSign)
        logger.debug("Did register an account: \(account)")
    }

    func isIdentityRegistered(account: Account) -> Bool {
        return identityClient.isIdentityRegistered(account: account)
    }
}

private extension NotifyIdentityService {

    func makeStatement() -> String {
            return "I further authorize this app to send and receive messages on my behalf using my WalletConnect identity. Read more at https://walletconnect.com/identity"
    }
}
