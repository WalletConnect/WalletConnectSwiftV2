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
        let statement = makeStatement(isLimited: isLimited)
        _ = try await identityClient.register(account: account,
            domain: domain,
            statement: statement,
            resources: [keyserverURL.absoluteString],
            onSign: onSign)
    }

    public func unregister(account: Account) async throws {
        try await identityClient.unregister(account: account)
    }

    func isIdentityRegistered(account: Account) -> Bool {
        return identityClient.isIdentityRegistered(account: account)
    }
}

private extension NotifyIdentityService {

    func makeStatement(isLimited: Bool) -> String {
        switch isLimited {
        case true:
            return "I further authorize this app to send and receive messages on my behalf for THIS domain using my WalletConnect identity. Read more at https://walletconnect.com/identity"
        case false:
            return "I further authorize this app to send and receive messages on my behalf for ALL domains using my WalletConnect identity. Read more at https://walletconnect.com/identity"
        }
    }
}
