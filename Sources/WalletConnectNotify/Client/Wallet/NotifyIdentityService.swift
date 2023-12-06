import Foundation

// TODO: Remove
final class NotifyIdentityService {

    private let keyserverURL: URL
    private let identityClient: IdentityClient
    private let logger: ConsoleLogging

    init(keyserverURL: URL, identityClient: IdentityClient, logger: ConsoleLogging) {
        self.keyserverURL = keyserverURL
        self.identityClient = identityClient
        self.logger = logger
    }

    public func prepareRegistration(account: Account, domain: String, allApps: Bool) async throws -> IdentityRegistrationParams {
        return try await identityClient.prepareRegistration(
            account: account,
            domain: domain,
            statement: makeStatement(allApps: allApps),
            resources: [keyserverURL.absoluteString]
        )
    }

    public func register(params: IdentityRegistrationParams, signature: CacaoSignature) async throws {
        try await identityClient.register(params: params, signature: signature)
    }

    public func unregister(account: Account) async throws {
        try await identityClient.unregister(account: account)
    }

    func isIdentityRegistered(account: Account) -> Bool {
        return identityClient.isIdentityRegistered(account: account)
    }
}

private extension NotifyIdentityService {

    func makeStatement(allApps: Bool) -> String {
        switch allApps {
        case false:
            return "I further authorize this app to send me notifications. Read more at https://walletconnect.com/notifications"
        case true:
            return "I further authorize this app to view and manage my notifications for ALL apps. Read more at https://walletconnect.com/notifications"
        }
    }
}
