import Foundation

enum SessionEngineError: Error {
    case unauthorizedTargetChain
    case noSettledSessionForPayload
    case unauthorizedMethod
}

final class SessionEngine {
    let sequences: Sequences<Session>
    private let wcSubscriber: WCSubscribing
    private let relayer: Relaying
    private let crypto: Crypto
    private var isController: Bool
    private var metadata: AppMetadata
    var onSessionApproved: ((SessionType.Settled)->())?
    var onPayload: ((SessionRequest)->())?

    init(relay: Relaying,
         crypto: Crypto,
         subscriber: WCSubscribing,
         isController: Bool,
         metadata: AppMetadata) {
        self.relayer = relay
        self.crypto = crypto
        self.metadata = metadata
        self.wcSubscriber = subscriber
        self.sequences = Sequences<Session>()
        self.isController = isController
        setUpWCRequestHandling()
    }
    
    func approve(proposal: SessionType.Proposal, completion: @escaping (Result<SessionType.Settled, Error>) -> Void) {
        Logger.debug("Approve session")
        let privateKey = Crypto.X25519.generatePrivateKey()
        let selfPublicKey = privateKey.publicKey.toHexString()
        
        let pendingSession = SessionType.Pending(status: .responded,
                                                 topic: proposal.topic,
                                                 relay: proposal.relay,
                                                 self: SessionType.Participant(publicKey: selfPublicKey, metadata: metadata),
                                                 proposal: proposal)
        
        sequences.create(topic: proposal.topic, sequenceState: .pending(pendingSession))
        wcSubscriber.setSubscription(topic: proposal.topic)
        
        let agreementKeys = try! Crypto.X25519.generateAgreementKeys(
            peerPublicKey: Data(hex: proposal.proposer.publicKey),
            privateKey: privateKey)
        let settledTopic = agreementKeys.sharedSecret.sha256().toHexString()
        
        let settledSession = SessionType.Settled(
            topic: settledTopic,
            relay: proposal.relay,
            sharedKey: agreementKeys.sharedSecret.toHexString(),
            self: SessionType.Participant(publicKey: selfPublicKey, metadata: AppMetadata(name: nil, description: nil, url: nil, icons: nil)),
            peer: SessionType.Participant(publicKey: proposal.proposer.publicKey, metadata: proposal.proposer.metadata),
            permissions: pendingSession.proposal.permissions,
            expiry: Int(Date().timeIntervalSince1970) + proposal.ttl,
            state: SessionType.State(accounts: [])) // FIXME: State
        
        let approveParams = SessionType.ApproveParams(
            topic: proposal.topic,
            relay: proposal.relay,
            responder: SessionType.Participant(
                publicKey: selfPublicKey,
                metadata: AppMetadata(name: nil, description: nil, url: nil, icons: nil)), // FIXME: Metadata
            expiry: Int(Date().timeIntervalSince1970) + proposal.ttl,
            state: SessionType.State(accounts: [])) // FIXME: State
        let approvalPayload = ClientSynchJSONRPC(method: .sessionApprove, params: .sessionApprove(approveParams))
        
        _ = try? relayer.publish(topic: proposal.topic, payload: approvalPayload) { [weak self] result in
            switch result {
            case .success:
                self?.crypto.set(agreementKeys: agreementKeys, topic: settledTopic)
                self?.crypto.set(privateKey: privateKey)
                self?.sequences.update(topic: proposal.topic, newTopic: settledTopic, sequenceState: .settled(settledSession))
                self?.wcSubscriber.setSubscription(topic: settledTopic)
                print("Success on wc_sessionApprove, published on topic: \(proposal.topic), settled topic: \(settledTopic)")
                completion(.success(settledSession))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func reject(proposal: SessionType.Proposal, reason: SessionType.Reason) {
        let rejectParams = SessionType.RejectParams(reason: reason)
        let rejectPayload = ClientSynchJSONRPC(method: .sessionReject, params: .sessionReject(rejectParams))
        _ = try? relayer.publish(topic: proposal.topic, payload: rejectPayload) { result in
            print("Reject result: \(result)")
        }
    }
    
    func delete(params: SessionType.DeleteParams) {
        Logger.debug("Will delete session for reason: message: \(params.reason.message) code: \(params.reason.code)")
        sequences.delete(topic: params.topic)
        wcSubscriber.removeSubscription(topic: params.topic)
        do {
            _ = try relayer.publish(topic: params.topic, payload: params) { result in
                print("Session Delete result: \(result)")
            }
        }  catch {
            Logger.error(error)
        }
    }
    
    func proposeSession(settledPairing: PairingType.Settled, permissions: SessionType.Permissions) {
        guard let pendingSessionTopic = generateTopic() else {
            Logger.debug("Could not generate topic")
            return
        }
        Logger.debug("Propose Session on topic: \(pendingSessionTopic)")
        let privateKey = Crypto.X25519.generatePrivateKey()
        let publicKey = privateKey.publicKey.toHexString()
        crypto.set(privateKey: privateKey)
        let proposer = SessionType.Proposer(publicKey: publicKey, controller: isController, metadata: metadata)
        let signal = SessionType.Signal(method: "pairing", params: SessionType.Signal.Params(topic: settledPairing.topic))
        let proposal = SessionType.Proposal(topic: pendingSessionTopic, relay: settledPairing.relay, proposer: proposer, signal: signal, permissions: permissions, ttl: getDefaultTTL())
        let selfParticipant = SessionType.Participant(publicKey: publicKey, metadata: metadata)
        let pending = SessionType.Pending(status: .proposed, topic: pendingSessionTopic, relay: settledPairing.relay, self: selfParticipant, proposal: proposal)
        sequences.create(topic: pendingSessionTopic, sequenceState: .pending(pending))
        wcSubscriber.setSubscription(topic: pendingSessionTopic)
        let jsonRpcRequest = JSONRPCRequest<SessionType.ProposeParams>(method: ClientSynchJSONRPC.Method.sessionPropose.rawValue, params: proposal)
        let request = PairingType.PayloadParams.Request(method: .sessionPropose, params: jsonRpcRequest)
        let pairingPayloadParams = PairingType.PayloadParams(request: request)
        let pairingPayloadRequest = ClientSynchJSONRPC(method: .pairingPayload, params: .pairingPayload(pairingPayloadParams))
        _ = try? relayer.publish(topic: settledPairing.topic, payload: pairingPayloadRequest) { [unowned self] result in
            switch result {
            case .success:
                Logger.debug("Sent Session Proposal")
            case .failure(let error):
                Logger.debug("Could not send session proposal error: \(error)")
            }
        }
    }
    
    func request(params: SessionType.RequestParams) {
        guard let _ = sequences.get(topic: params.topic) else {
            Logger.debug("Could not find session for topic \(params.topic)")
            return
        }
        let request = SessionType.PayloadParams.Request(method: params.method, params: params.params)
        let sessionPayloadParams = SessionType.PayloadParams(request: request, chainId: params.chainId)
        let sessionPayloadRequest = ClientSynchJSONRPC(method: .sessionPayload, params: .sessionPayload(sessionPayloadParams))
        _ = try? relayer.publish(topic: params.topic, payload: sessionPayloadRequest) { [unowned self] result in
            switch result {
            case .success:
                Logger.debug("Sent Session Payload")
            case .failure(let error):
                Logger.debug("Could not send session payload, error: \(error)")
            }
        }
    }
    
    //MARK: - Private

    private func getDefaultTTL() -> Int {
        7 * Time.day
    }
    
    private func generateTopic() -> String? {
        var keyData = Data(count: 32)
        let result = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }
        if result == errSecSuccess {
            return keyData.toHexString()
        } else {
            print("Problem generating random bytes")
            return nil
        }
    }
    
    private func getDefaultPermissions() -> PairingType.ProposedPermissions {
        PairingType.ProposedPermissions(jsonrpc: PairingType.JSONRPC(methods: [PairingType.PayloadMethods.sessionPropose.rawValue]))
    }
    
    private func setUpWCRequestHandling() {
        wcSubscriber.onSubscription = { [unowned self] subscriptionPayload in
            switch subscriptionPayload.clientSynchJsonRpc.params {
            case .sessionApprove(let approveParams):
                self.handleSessionApprove(approveParams)
            case .sessionReject(_):
                fatalError("Not implemented")
            case .sessionUpdate(_):
                fatalError("Not implemented")
            case .sessionUpgrade(_):
                fatalError("Not implemented")
            case .sessionDelete(_):
                fatalError("Not implemented")
            case .sessionPayload(let sessionPayloadParams):
                let jsonRpcRequest = JSONRPCRequest<String>(id: subscriptionPayload.clientSynchJsonRpc.id, method: sessionPayloadParams.request.method, params: sessionPayloadParams.request.params)
                let sessionRequest = SessionRequest(topic: subscriptionPayload.topic, request: jsonRpcRequest, chainId: sessionPayloadParams.chainId)
                self.handleSessionPayload(sessionRequest)
            default:
                fatalError("unexpected method type")
            }
        }
    }
    
    private func handleSessionPayload(_ sessionRequest: SessionRequest) {
        do {
            try validatePayload(sessionRequest)
            onPayload?(sessionRequest)
        } catch {
            Logger.error(error)
        }
    }
    
    private func validatePayload(_ sessionRequest: SessionRequest) throws {
        guard let session = sequences.get(topic: sessionRequest.topic),
              case .settled(let sequenceSettled) = session.sequenceState,
        let settledSession = sequenceSettled as? SessionType.Settled else {
            throw SessionEngineError.noSettledSessionForPayload
        }
        if let chainId = sessionRequest.chainId {
            guard settledSession.permissions.blockchain.chains.contains(chainId) else {
                throw SessionEngineError.unauthorizedTargetChain
            }
        }
        guard settledSession.permissions.jsonrpc.methods.contains(sessionRequest.request.method) else {
            throw SessionEngineError.unauthorizedMethod
        }
    }
    
    private func handleSessionApprove(_ approveParams: SessionType.ApproveParams) {
        Logger.debug("Responder Client approved session on topic: \(approveParams.topic)")
        guard let session = sequences.get(topic: approveParams.topic),
              case let .pending(sequencePending) = session.sequenceState,
              let pendingSession = sequencePending as? SessionType.Pending else {
          fatalError()
        }
        let selfPublicKey = Data(hex: pendingSession.`self`.publicKey)
        let privateKey = try! crypto.getPrivateKey(for: selfPublicKey)!
        let peerPublicKey = Data(hex: approveParams.responder.publicKey)
        let agreementKeys = try! Crypto.X25519.generateAgreementKeys(peerPublicKey: peerPublicKey, privateKey: privateKey)
        let settledTopic = agreementKeys.sharedSecret.sha256().toHexString()
        crypto.set(agreementKeys: agreementKeys, topic: settledTopic)
        let proposal = pendingSession.proposal
        let controllerKey = proposal.proposer.controller ? selfPublicKey.toHexString() : proposal.proposer.publicKey
        let controller = Controller(publicKey: controllerKey)
        let proposedPermissions = pendingSession.proposal.permissions
        let sessionPermissions = SessionType.Permissions(blockchain: proposedPermissions.blockchain, jsonrpc: proposedPermissions.jsonrpc, notifications: proposedPermissions.notifications, controller: controller)
        
        let settledSession = SessionType.Settled(
            topic: settledTopic,
            relay: approveParams.relay,
            sharedKey: agreementKeys.sharedSecret.toHexString(),
            self: SessionType.Participant(publicKey: selfPublicKey.toHexString(), metadata: metadata),
            peer: SessionType.Participant(publicKey: approveParams.responder.publicKey, metadata: approveParams.responder.metadata),
            permissions: sessionPermissions,
            expiry: approveParams.expiry,
            state: approveParams.state)
        
        sequences.update(topic: proposal.topic, newTopic: settledTopic, sequenceState: .settled(settledSession))
        wcSubscriber.setSubscription(topic: settledTopic)
        wcSubscriber.removeSubscription(topic: proposal.topic)
        onSessionApproved?(settledSession)
    }
}
