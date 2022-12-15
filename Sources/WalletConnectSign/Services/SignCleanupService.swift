import Foundation

final class SignCleanupService {

    private let pairingStore: WCPairingStorage
    private let sessionStore: WCSessionStorage
    private let kms: KeyManagementServiceProtocol
    private let sessionToPairingTopic: CodableStore<String>
    private let networkInteractor: NetworkInteracting

    init(pairingStore: WCPairingStorage, sessionStore: WCSessionStorage, kms: KeyManagementServiceProtocol, sessionToPairingTopic: CodableStore<String>, networkInteractor: NetworkInteracting) {
        self.pairingStore = pairingStore
        self.sessionStore = sessionStore
        self.sessionToPairingTopic = sessionToPairingTopic
        self.networkInteractor = networkInteractor
        self.kms = kms
    }

    func cleanup() async throws {
        try await unsubscribe()

        pairingStore.deleteAll()
        sessionStore.deleteAll()
        sessionToPairingTopic.deleteAll()
        try kms.deleteAll()
    }
}

private extension SignCleanupService {

    func unsubscribe() async throws {
        let pairing = pairingStore.getAll().map { $0.topic }
        let session = sessionStore.getAll().map { $0.topic }

        try await networkInteractor.batchUnsubscribe(topics: pairing + session)
    }
}
