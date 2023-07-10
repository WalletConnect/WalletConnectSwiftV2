import Foundation

final class SyncRegisterService {

    private let syncClient: SyncClient

    init(syncClient: SyncClient) {
        self.syncClient = syncClient
    }

    func register(account: Account, onSign: @escaping SigningCallback) async throws {
        let message = syncClient.getMessage(account: account)

        switch await onSign(message) {
        case .signed(let signature):
            try await syncClient.register(account: account, signature: signature)
        case .rejected:
            throw Errors.signatureRejected
        }
    }

    func isRegistered(account: Account) -> Bool {
        return syncClient.isRegistered(account: account)
    }
}

private extension SyncRegisterService {

    enum Errors: Error {
        case signatureRejected
    }
}
