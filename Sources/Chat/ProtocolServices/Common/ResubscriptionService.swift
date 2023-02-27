import Foundation
import Combine

class ResubscriptionService {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let accountService: AccountService
    private let logger: ConsoleLogging
    private var chatStorage: ChatStorage
    private var publishers = [AnyCancellable]()

    init(
        networkingInteractor: NetworkInteracting,
        kms: KeyManagementServiceProtocol,
        accountService: AccountService,
        chatStorage: ChatStorage,
        logger: ConsoleLogging
    ) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.accountService = accountService
        self.logger = logger
        self.chatStorage = chatStorage

        setUpResubscription()
    }

    func setUpResubscription() {
        networkingInteractor.socketConnectionStatusPublisher
            .sink { [unowned self] status in
                guard status == .connected else { return }

                Task(priority: .high) {
                    let topics = chatStorage.getAllThreads().map { $0.topic }
                    try await networkingInteractor.batchSubscribe(topics: topics)
                }
            }.store(in: &publishers)
    }

    func subscribeForInvites(inviteKey: AgreementPublicKey) async throws {
        let topic = inviteKey.rawRepresentation.sha256().toHexString()
        try kms.setPublicKey(publicKey: inviteKey, for: topic)
        try await networkingInteractor.subscribe(topic: topic)
    }

    func unsubscribeFromInvites(inviteKey: AgreementPublicKey) {
        let topic = inviteKey.rawRepresentation.sha256().toHexString()
        kms.deletePublicKey(for: topic)
        networkingInteractor.unsubscribe(topic: topic)
    }
}
