import Foundation

final class ThreadStoreDelegate {

    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol

    init(networkingInteractor: NetworkInteracting, kms: KeyManagementServiceProtocol) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
    }

    func onInitialization(_ threads: [Thread]) async throws {
        let topics = threads.map { $0.topic }
        try await networkingInteractor.batchSubscribe(topics: topics)
    }

    func onUpdate(_ thread: Thread) async throws {
        let symmetricKey = try SymmetricKey(hex: thread.symKey)
        try kms.setSymmetricKey(symmetricKey, for: thread.topic)
        try await networkingInteractor.subscribe(topic: thread.topic)
    }

    func onDelete(_ id: String) async throws {

    }
}
