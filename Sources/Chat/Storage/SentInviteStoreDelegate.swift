import Foundation

final class SentInviteStoreDelegate {

    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol

    init(networkingInteractor: NetworkInteracting, kms: KeyManagementServiceProtocol) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
    }

    func onInitialization(_ objects: [SentInvite]) async throws {
        for invite in objects {
            try syncKeychain(invite: invite)
        }

        let topics = objects.map { $0.responseTopic }
        try await networkingInteractor.batchSubscribe(topics: topics)
    }

    func onUpdate(_ object: SentInvite) {
        Task(priority: .high) {
            try syncKeychain(invite: object)
            try await networkingInteractor.subscribe(topic: object.responseTopic)
        }
    }

    func onDelete(_ object: SentInvite) {
        // TODO: Implement unsubscribe
    }
}

private extension SentInviteStoreDelegate {

    func syncKeychain(invite: SentInvite) throws {
        let symmetricKey = try SymmetricKey(hex: invite.symKey)
        let agreementPrivateKey = try AgreementPrivateKey(hex: invite.inviterPrivKeyY)

        // TODO: Should we set symKey for inviteTopic???
        try kms.setSymmetricKey(symmetricKey, for: invite.responseTopic)
        try kms.setPrivateKey(agreementPrivateKey)
    }
}
