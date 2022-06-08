

import Foundation
import WalletConnectKMS
import WalletConnectUtils
import Combine

class InviteService {
    private var publishers = [AnyCancellable]()
    let networkingInteractor: NetworkingInteractor
    let logger: ConsoleLogging
    let kms: KeyManagementService
    
    var onInvite: ((InviteParams)->())?

    init(networkingInteractor: NetworkingInteractor,
         kms: KeyManagementService,
         logger: ConsoleLogging) {
        self.kms = kms
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        setUpResponseHandling()
    }
        
    func invite(peerPubKey: String, openingMessage: String, account: Account) async throws {
        let pubKey = try kms.createX25519KeyPair()
        let invite = Invite(message: openingMessage, account: account)
        let encodedInvite = encode(invite: invite)
        let inviteRequestParams = InviteParams(pubKey: pubKey.hexRepresentation, invite: encodedInvite)
        let topic = try AgreementPublicKey(hex: peerPubKey).rawRepresentation.sha256().toHexString()
        let request = ChatRequest(params: .invite(inviteRequestParams))
        networkingInteractor.requestUnencrypted(request, topic: topic)
        let agreementKeys = try kms.performKeyAgreement(selfPublicKey: pubKey, peerPublicKey: peerPubKey)
        let threadTopic = agreementKeys.derivedTopic()
        try await networkingInteractor.subscribe(topic: threadTopic)
        logger.debug("invite sent on topic: \(topic)")
    }
    
    private func setUpResponseHandling() {
        networkingInteractor.responsePublisher
            .sink { [unowned self] response in
            switch response.requestMethod {
            case .invite:
                switch response.result {
                case .error(_):
                    logger.debug("Invite has been rejected")
                case .response(_):
                    logger.debug("Invite has been accepted")
                }
            default:
                return
            }
        }.store(in: &publishers)
    }
    
    private func encode(invite: Invite) -> String {
        //TODO - serialise an invite
        fatalError("not implemented")
    }

}
