import Foundation

final class PushSyncService {

    private let syncClient: SyncClient
    private let logger: ConsoleLogging

    init(syncClient: SyncClient, logger: ConsoleLogging) {
        self.syncClient = syncClient
        self.logger = logger
    }

    func registerIfNeeded(account: Account, onSign: @escaping SigningCallback) async throws {
        guard !syncClient.isRegistered(account: account) else { return }

        let result = await onSign(syncClient.getMessage(account: account))

        switch result {
        case .signed(let signature):
            try await syncClient.register(account: account, signature: signature)
            logger.debug("Sync pushSubscriptions store registered and initialized")
        case .rejected:
            throw PushError.registerSignatureRejected
        }
    }
}
