import Foundation
import Combine

class ResubscriptionService {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    private var publishers = [AnyCancellable]()

    init(
        networkingInteractor: NetworkInteracting,
        kms: KeyManagementServiceProtocol,
        logger: ConsoleLogging
    ) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
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
