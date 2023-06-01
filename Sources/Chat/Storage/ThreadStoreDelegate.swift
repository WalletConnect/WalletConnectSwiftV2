import Foundation

final class ThreadStoreDelegate {

    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let historyClient: HistoryClient
    private let serializer: Serializing

    init(networkingInteractor: NetworkInteracting, kms: KeyManagementServiceProtocol, historyClient: HistoryClient, serializer: Serializing) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.serializer = serializer
        self.historyClient = historyClient
    }

    func onInitialization(storage: ChatStorage) async throws {
        let threads = storage.getAllThreads()
        try await networkingInteractor.batchSubscribe(topics: threads.map { $0.topic })

        for thread in threads {
            try await fetchMessageHistory(thread: thread, storage: storage)
        }
    }

    func onUpdate(_ thread: Thread, storage: ChatStorage) {
        Task(priority: .high) {
            for receivedInvite in storage.getReceivedInvites(thread: thread) {
                storage.accept(receivedInvite: receivedInvite, account: thread.selfAccount)
            }

            let symmetricKey = try SymmetricKey(hex: thread.symKey)
            try kms.setSymmetricKey(symmetricKey, for: thread.topic)
            try await networkingInteractor.subscribe(topic: thread.topic)

            // Relay Client injection!
        }
    }

    func onDelete(_ id: String) {

    }
}

private extension ThreadStoreDelegate {

    func fetchMessageHistory(thread: Thread, storage: ChatStorage) async throws {
        let historyPayload = GetMessagesPayload(topic: thread.topic, originId: nil, messageCount: 200, direction: .forward)
        let response = try await historyClient.getMessages(payload: historyPayload, historyUrl: "https://history.walletconnect.com")

        for messagePayload in response.messages {
            let (request, _, _): (RPCRequest, _, _) = try serializer.deserialize(
                topic: thread.topic,
                encodedEnvelope: messagePayload
            )

            let wrapper = try request.params!.get(MessagePayload.Wrapper.self)

            let (messagePayload, messageClaims) = try MessagePayload.decodeAndVerify(from: wrapper)

            let authorAccount = messagePayload.recipientAccount == thread.selfAccount
                ? thread.peerAccount
                : thread.selfAccount

            let message = Message(
                topic: thread.topic,
                message: messagePayload.message,
                authorAccount: authorAccount,
                timestamp: messageClaims.iat)

            storage.set(message: message, account: thread.selfAccount)
        }
    }
}
