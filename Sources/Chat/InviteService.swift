

import Foundation
import WalletConnectKMS
import WalletConnectUtils
import Combine

class InviteService {
    private var publishers = [AnyCancellable]()
    let networkingInteractor: NetworkingInteractor
    let logger: ConsoleLogging
    let kms: KeyManagementService
    let serializer: Serializing
    
    var onInvite: ((InviteParams)->())?

    init(networkingInteractor: NetworkingInteractor,
         kms: KeyManagementService,
         logger: ConsoleLogging,
         serializer: Serializing) {
        self.kms = kms
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.serializer = serializer
        setUpResponseHandling()
    }
        
    func invite(peerPubKey: String, openingMessage: String, account: Account) async throws {
        let selfPubKeyY = try kms.createX25519KeyPair()
        let invite = Invite(message: openingMessage, account: account)
        
        let symKeyI = try kms.performKeyAgreement(selfPublicKey: selfPubKeyY, peerPublicKey: peerPubKey)
        let inviteTopic = try AgreementPublicKey(hex: peerPubKey).rawRepresentation.sha256().toHexString()
        
        let encodedInvite = try serializer.serialize(topic: inviteTopic, encodable: invite)
        
        let inviteRequestParams = InviteParams(pubKey: selfPubKeyY.hexRepresentation, invite: encodedInvite)
        
        try kms.setSymmetricKey(symKeyI.sharedKey, for: inviteTopic)
        
        let request = ChatRequest(params: .invite(inviteRequestParams))
        
        networkingInteractor.requestUnencrypted(request, topic: inviteTopic)
        logger.debug("invite sent on topic: \(inviteTopic)")
    }
    
    private func setUpResponseHandling() {
        networkingInteractor.responsePublisher
            .sink { [unowned self] response in
                switch response.requestMethod {
                case .invite:
                    handleInviteResponse(response)
                default:
                    return
                }
            }.store(in: &publishers)
    }
    
    private func handleInviteResponse(_ response: ChatResponse) {
        switch response.result {
        case .error(_):
            logger.debug("Invite has been rejected")
            //TODO - remove keys, clean storage
        case .response(let jsonrpc):
            do {
                let inviteResponse = try jsonrpc.result.get(InviteResponse.self)
                logger.debug("Invite has been accepted")
                guard case .invite(let inviteParams) = response.requestParams else { return }
                Task { try await createThread(selfPubKeyHex: inviteParams.pubKey, peerPubKey: inviteResponse.pubKey)}
            } catch {
                logger.debug("Handling invite response has failed")
            }
        }
    }
    
    private func createThread(selfPubKeyHex: String, peerPubKey: String) async throws {
        let selfPubKey = try AgreementPublicKey(hex: selfPubKeyHex)
        let agreementKeys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPubKey)
        let threadTopic = agreementKeys.derivedTopic()
        try await networkingInteractor.subscribe(topic: threadTopic)
    }
}
