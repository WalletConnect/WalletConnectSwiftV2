import Foundation

final class ThreadStoreDelegate {

    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let historyService: HistoryService

    init(networkingInteractor: NetworkInteracting, kms: KeyManagementServiceProtocol, historyService: HistoryService) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.historyService = historyService
    }

    func onInitialization(storage: ChatStorage) async throws {
        let threads = storage.getAllThreads()
        try await networkingInteractor.batchSubscribe(topics: threads.map { $0.topic })
    }

    func onUpdate(_ thread: Thread, storage: ChatStorage) {
        Task(priority: .high) {
            for receivedInvite in storage.getReceivedInvites(thread: thread) {
                storage.accept(receivedInvite: receivedInvite, account: thread.selfAccount)
            }

            let symmetricKey = try SymmetricKey(hex: thread.symKey)
            try kms.setSymmetricKey(symmetricKey, for: thread.topic)
            try await networkingInteractor.subscribe(topic: thread.topic)

            let messages = try await historyService.fetchMessageHistory(thread: thread)
            storage.set(messages: messages, account: thread.selfAccount)
        }
    }

    func onDelete(_ object: Thread) {

    }
}
