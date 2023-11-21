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
            return "I further authorize this app to send me notifications. Read more at https://walletconnect.com/notifications"
        case false:
            return "I further authorize this app to view and manage my notifications for ALL apps. Read more at https://walletconnect.com/notifications"
        }
    }
}
