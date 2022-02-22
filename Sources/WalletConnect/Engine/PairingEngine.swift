import Foundation
import Combine
import WalletConnectUtils
import WalletConnectKMS

final class PairingEngine {
    var onApprovalAcknowledgement: ((Pairing) -> Void)?
    var onSessionProposal: ((SessionProposal)->())?
    var onPairingApproved: ((Pairing, SessionPermissions, RelayProtocolOptions)->())?
    var onPairingExtend: ((Pairing)->())?
    
    private let wcSubscriber: WCSubscribing
    private let relayer: WalletConnectRelaying
    private let kms: KeyManagementServiceProtocol
    private let sequencesStore: PairingSequenceStorage
    private var appMetadata: AppMetadata
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging
    private var sessionPermissions: [String: SessionPermissions] = [:]
    private let topicInitializer: () -> String?
    
    init(relay: WalletConnectRelaying,
         kms: KeyManagementServiceProtocol,
         subscriber: WCSubscribing,
         sequencesStore: PairingSequenceStorage,
         metadata: AppMetadata,
         logger: ConsoleLogging,
         topicGenerator: @escaping () -> String? = String.generateTopic) {
        self.relayer = relay
        self.kms = kms
        self.wcSubscriber = subscriber
        self.appMetadata = metadata
        self.sequencesStore = sequencesStore
        self.logger = logger
        self.topicInitializer = topicGenerator
        setUpWCRequestHandling()
        setupExpirationHandling()
        removeRespondedPendingPairings()
        restoreSubscriptions()
        
        relayer.onPairingResponse = { [weak self] in
            self?.handleReponse($0)
        }
    }
    
    func hasPairing(for topic: String) -> Bool {
        return sequencesStore.hasSequence(forTopic: topic)
    }
    
    func getSettledPairing(for topic: String) -> PairingSequence? {
        guard let pairing = sequencesStore.getSequence(forTopic: topic), pairing.isSettled else {
            return nil
        }
        return pairing
    }
    
    func getSettledPairings() -> [Pairing] {
        sequencesStore.getAll()
            .filter { $0.isSettled }
            .map { Pairing(topic: $0.topic, peer: $0.settled?.state?.metadata, expiryDate: $0.expiryDate) }
    }
    
    func propose(permissions: SessionPermissions) -> WalletConnectURI? {
        guard let topic = topicInitializer() else {
            logger.debug("Could not generate topic")
            return nil
        }
        
        let publicKey = try! kms.createX25519KeyPair()
        
        let relay = RelayProtocolOptions(protocol: "waku", params: nil)
        let uri = WalletConnectURI(topic: topic, publicKey: publicKey.hexRepresentation, isController: false, relay: relay)
        let pendingPairing = PairingSequence.buildProposed(uri: uri)
        
        sequencesStore.setSequence(pendingPairing)
        wcSubscriber.setSubscription(topic: topic)
        sessionPermissions[topic] = permissions
        return uri
    }
    
    func approve(_ pairingURI: WalletConnectURI) throws {
        let proposal = PairingProposal.createFromURI(pairingURI)
        guard !proposal.proposer.controller else {
            throw WalletConnectError.internal(.unauthorizedMatchingController)
        }
        guard !hasPairing(for: proposal.topic) else {
            throw WalletConnectError.internal(.pairWithExistingPairingForbidden)
        }
        
        let selfPublicKey = try! kms.createX25519KeyPair()
        let agreementKeys = try! kms.performKeyAgreement(selfPublicKey: selfPublicKey, peerPublicKey: proposal.proposer.publicKey)
        
        let settledTopic = agreementKeys.derivedTopic()
        let pendingPairing = PairingSequence.buildResponded(proposal: proposal, agreementKeys: agreementKeys)
        let settledPairing = PairingSequence.buildPreSettled(proposal: proposal, agreementKeys: agreementKeys)
        
        wcSubscriber.setSubscription(topic: proposal.topic)
        sequencesStore.setSequence(pendingPairing)
        wcSubscriber.setSubscription(topic: settledTopic)
        sequencesStore.setSequence(settledPairing)
        
        try? kms.setAgreementSecret(agreementKeys, topic: settledTopic)
        
        let approval = PairingType.ApprovalParams(
            relay: proposal.relay,
            responder: PairingParticipant(publicKey: selfPublicKey.hexRepresentation),
            expiry: Int(Date().timeIntervalSince1970) + proposal.ttl,
            state: nil) // Should this be removed?
        
        relayer.request(.wcPairingApprove(approval), onTopic: proposal.topic)
    }
    
    func ping(topic: String, completion: @escaping ((Result<Void, Error>) -> ())) {
        guard sequencesStore.hasSequence(forTopic: topic) else {
            logger.debug("Could not find pairing to ping for topic \(topic)")
            return
        }
        relayer.request(.wcPairingPing, onTopic: topic) { [unowned self] result in
            switch result {
            case .success(_):
                logger.debug("Did receive ping response")
                completion(.success(()))
            case .failure(let error):
                logger.debug("error: \(error)")
            }
        }
    }
    
    func extend(topic: String, ttl: Int) throws {
        guard var pairing = sequencesStore.getSequence(forTopic: topic) else {
            throw WalletConnectError.noPairingMatchingTopic(topic)
        }
        guard pairing.isSettled else {
            throw WalletConnectError.pairingNotSettled(topic)
        }
        guard pairing.selfIsController else {
            throw WalletConnectError.unauthorizedNonControllerCall
        }
        try pairing.extend(ttl)
        sequencesStore.setSequence(pairing)
        relayer.request(.wcPairingExtend(PairingType.ExtendParams(ttl: ttl)), onTopic: topic)
    }
    
    //MARK: - Private
    
    private func acknowledgeApproval(pendingTopic: String) {
        guard
            let pendingPairing = sequencesStore.getSequence(forTopic: pendingTopic),
            case .responded(let settledTopic) = pendingPairing.pending?.status,
            var settledPairing = sequencesStore.getSequence(forTopic: settledTopic)
        else { return }
        
        settledPairing.settled?.status = .acknowledged
        sequencesStore.setSequence(settledPairing)
        wcSubscriber.removeSubscription(topic: pendingTopic)
        sequencesStore.delete(topic: pendingTopic)
        
        let pairing = Pairing(topic: settledPairing.topic, peer: nil, expiryDate: settledPairing.expiryDate)
        onApprovalAcknowledgement?(pairing)
        update(topic: settledPairing.topic)
        logger.debug("Success on wc_pairingApprove - settled topic - \(settledTopic)")
        logger.debug("Pairing Success")
    }

    private func setUpWCRequestHandling() {
        wcSubscriber.onReceivePayload = { [unowned self] subscriptionPayload in
            switch subscriptionPayload.wcRequest.params {
            case .pairingApprove(let approveParams):
                wcPairingApprove(subscriptionPayload, approveParams: approveParams)
            case .pairingPayload(let pairingPayload):
                wcPairingPayload(subscriptionPayload, payloadParams: pairingPayload)
            case .pairingPing(_):
                wcPairingPing(subscriptionPayload)
            default:
                logger.warn("Warning: Pairing Engine - Unexpected method type: \(subscriptionPayload.wcRequest.method) received from subscriber")
            }
        }
    }
    
    private func wcPairingApprove(_ payload: WCRequestSubscriptionPayload, approveParams: PairingType.ApprovalParams) {
        let pendingPairingTopic = payload.topic
        guard let pairing = sequencesStore.getSequence(forTopic: pendingPairingTopic), let pendingPairing = pairing.pending else {
            relayer.respondError(for: payload, reason: .noContextWithTopic(context: .pairing, topic: pendingPairingTopic))
            return
        }
        
        let agreementKeys = try! kms.performKeyAgreement(selfPublicKey: try! pairing.getPublicKey(), peerPublicKey: approveParams.responder.publicKey)
        
        let settledTopic = agreementKeys.sharedSecret.sha256().toHexString()
        try? kms.setAgreementSecret(agreementKeys, topic: settledTopic)
        let proposal = pendingPairing.proposal
        let settledPairing = PairingSequence.buildAcknowledged(approval: approveParams, proposal: proposal, agreementKeys: agreementKeys)
        
        sequencesStore.setSequence(settledPairing)
        sequencesStore.delete(topic: pendingPairingTopic)
        wcSubscriber.setSubscription(topic: settledTopic)
        wcSubscriber.removeSubscription(topic: proposal.topic)
        
        guard let permissions = sessionPermissions[pendingPairingTopic] else {
            logger.debug("Cound not find permissions for pending topic: \(pendingPairingTopic)")
            return
        }
        sessionPermissions[pendingPairingTopic] = nil
        
        relayer.respondSuccess(for: payload)
        onPairingApproved?(Pairing(topic: settledPairing.topic, peer: nil, expiryDate: settledPairing.expiryDate), permissions, settledPairing.relay)
    }
    
    private func wcPairingExtend(_ payload: WCRequestSubscriptionPayload, extendParams: PairingType.ExtendParams) {
        let topic = payload.topic
        guard var pairing = sequencesStore.getSequence(forTopic: topic) else {
            relayer.respondError(for: payload, reason: .noContextWithTopic(context: .pairing, topic: topic))
            return
        }
        guard pairing.peerIsController else {
            relayer.respondError(for: payload, reason: .unauthorizedExtendRequest(context: .pairing))
            return
        }
        do {
            try pairing.extend(extendParams.ttl)
        } catch {
            relayer.respondError(for: payload, reason: .invalidExtendRequest(context: .pairing))
            return
        }
        sequencesStore.setSequence(pairing)
        relayer.respondSuccess(for: payload)
        onPairingExtend?(Pairing(topic: pairing.topic, peer: pairing.settled?.state?.metadata, expiryDate: pairing.expiryDate))
    }
    
    private func wcPairingPayload(_ payload: WCRequestSubscriptionPayload, payloadParams: PairingType.PayloadParams) {
        guard sequencesStore.hasSequence(forTopic: payload.topic) else {
            relayer.respondError(for: payload, reason: .noContextWithTopic(context: .pairing, topic: payload.topic))
            return
        }
        guard payloadParams.request.method == PairingType.PayloadMethods.sessionPropose else {
            relayer.respondError(for: payload, reason: .unauthorizedRPCMethod(payloadParams.request.method.rawValue))
            return
        }
        let sessionProposal = payloadParams.request.params
        do {
            if let pairingAgreementSecret = try kms.getAgreementSecret(for: sessionProposal.signal.params.topic) {
                try kms.setAgreementSecret(pairingAgreementSecret, topic: sessionProposal.topic)
            } else {
                relayer.respondError(for: payload, reason: .missingOrInvalid("agreement keys"))
                return
            }
        } catch {
            relayer.respondError(for: payload, reason: .missingOrInvalid("agreement keys"))
            return
        }
        relayer.respondSuccess(for: payload)
        onSessionProposal?(sessionProposal)
    }
    
    private func wcPairingPing(_ payload: WCRequestSubscriptionPayload) {
        relayer.respondSuccess(for: payload)
    }
    
    private func removeRespondedPendingPairings() {
        sequencesStore.getAll().forEach {
            if let pending = $0.pending, pending.isResponded {
                sequencesStore.delete(topic: $0.topic)
            }
        }
    }
    
    private func restoreSubscriptions() {
        relayer.transportConnectionPublisher
            .sink { [unowned self] (_) in
                let topics = sequencesStore.getAll()
                    .map{$0.topic}
                topics.forEach{self.wcSubscriber.setSubscription(topic: $0)}
            }.store(in: &publishers)
    }
    
    private func setupExpirationHandling() {
        sequencesStore.onSequenceExpiration = { [weak self] topic, publicKey in
            self?.kms.deletePrivateKey(for: publicKey)
            self?.kms.deleteAgreementSecret(for: topic)
        }
    }
    
    private func handleReponse(_ response: WCResponse) {
        switch response.requestParams {
        case .pairingApprove:
            acknowledgeApproval(pendingTopic: response.topic)
        default:
            break
        }
    }
}
