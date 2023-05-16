import Foundation

final class InviteKeyDelegate {

    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let identityClient: IdentityClient

    init(networkingInteractor: NetworkInteracting, kms: KeyManagementServiceProtocol, identityClient: IdentityClient) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.identityClient = identityClient
    }

    func onInitialization(_ keys: [InviteKey]) async throws {
        for key in keys {
            try syncKms(key: key)
        }

        let topics = keys.map { $0.topic }
        try await networkingInteractor.batchSubscribe(topics: topics)
    }

    func onUpdate(_ key: InviteKey, account: Account) {
        Task(priority: .high) {
            try syncKms(key: key)
            try syncIdentityStorage(key: key, account: account)
            try await networkingInteractor.subscribe(topic: key.topic)
        }
    }

    func onDelete(_ id: String) {
        Task(priority: .high) {
            let inviteKey = try AgreementPublicKey(hex: id) // InviteKey id is pubKey hex
            let topic = inviteKey.rawRepresentation.sha256().toHexString()
            kms.deletePublicKey(for: topic)
            networkingInteractor.unsubscribe(topic: topic)
        }
    }
}

private extension InviteKeyDelegate {

    func syncKms(key: InviteKey) throws {
        let inviteKey = try AgreementPublicKey(hex: key.publicKey)
        let privateKey = try AgreementPrivateKey(hex: key.privateKey)
        try kms.setPublicKey(publicKey: inviteKey, for: key.topic)
        try kms.setPrivateKey(privateKey)
    }

    func syncIdentityStorage(key: InviteKey, account: Account) throws {
        let inviteKey = try AgreementPublicKey(hex: key.publicKey)
        try identityClient.setInviteKey(inviteKey, account: account)
    }
}

