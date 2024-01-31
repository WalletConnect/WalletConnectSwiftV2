import Foundation

final class SignCleanupService {

    private let pairingStore: WCPairingStorage
    private let sessionStore: WCSessionStorage
    private let kms: KeyManagementServiceProtocol
    private let sessionTopicToProposal: CodableStore<Session.Proposal>
    private let networkInteractor: NetworkInteracting
    private let rpcHistory: RPCHistory

    init(pairingStore: WCPairingStorage, sessionStore: WCSessionStorage, kms: KeyManagementServiceProtocol, sessionTopicToProposal: CodableStore<Session.Proposal>, networkInteractor: NetworkInteracting,
         rpcHistory: RPCHistory) {
        self.pairingStore = pairingStore
        self.sessionStore = sessionStore
        self.sessionTopicToProposal = sessionTopicToProposal
        self.networkInteractor = networkInteractor
        self.kms = kms
        self.rpcHistory = rpcHistory
    }

    func cleanup() async throws {
        try await unsubscribe()
        try cleanupStorages()
    }

    func cleanup() throws {
        try cleanupStorages()
    }
}

private extension SignCleanupService {

    func unsubscribe() async throws {
        let pairing = pairingStore.getAll().map { $0.topic }
        let session = sessionStore.getAll().map { $0.topic }

        try await networkInteractor.batchUnsubscribe(topics: pairing + session)
    }

    func cleanupStorages() throws {
        pairingStore.deleteAll()
        sessionStore.deleteAll()
        sessionTopicToProposal.deleteAll()
        rpcHistory.deleteAll()
        try kms.deleteAll()
    }
}
