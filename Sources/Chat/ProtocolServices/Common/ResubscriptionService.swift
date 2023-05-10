import Foundation
import Combine

class ResubscriptionService {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    private var chatStorage: ChatStorage
    private var publishers = [AnyCancellable]()

    init(
        networkingInteractor: NetworkInteracting,
        kms: KeyManagementServiceProtocol,
        chatStorage: ChatStorage,
        logger: ConsoleLogging
    ) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
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

    func subscribeForSyncInvites(account: Account) async throws {
        let invites = chatStorage.getSentInvites(account: account)

        for invite in invites {
            let symmetricKey = try SymmetricKey(hex: invite.symKey)
            let agreementPublicKey = try AgreementPublicKey(hex: invite.inviterPubKeyY)
            let agreementPrivateKey = try AgreementPrivateKey(hex: invite.inviterPrivKeyY)

            // TODO: Should we set symKey for inviteTopic???
            try kms.setSymmetricKey(symmetricKey, for: invite.responseTopic)
            try kms.setPublicKey(publicKey: agreementPublicKey, for: invite.responseTopic)
            try kms.setPrivateKey(agreementPrivateKey)
        }

        try await networkingInteractor.batchSubscribe(topics: invites.map { $0.responseTopic })
    }
}
