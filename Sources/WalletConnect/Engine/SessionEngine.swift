import Foundation
import Combine

final class SessionEngine {
    var sequencesStore: SessionSequencesStore
    private let wcSubscriber: WCSubscribing
    private let relayer: WalletConnectRelaying
    private let crypto: Crypto
    private var isController: Bool
    private var metadata: AppMetadata
    var onSessionApproved: ((SessionType.Settled)->())?
    var onSessionPayloadRequest: ((SessionRequest)->())?
    var onSessionRejected: ((String, SessionType.Reason)->())?
    var onSessionDelete: ((String, SessionType.Reason)->())?
    var onSessionUpgrade: ((String, SessionType.Permissions)->())?
    var onSessionUpdate: ((String, Set<String>)->())?
    var onNotificationReceived: ((String, SessionType.NotificationParams)->())?
    private var publishers = [AnyCancellable]()

    private let logger: BaseLogger

    init(relay: WalletConnectRelaying,
         crypto: Crypto,
         subscriber: WCSubscribing,
         sequencesStore: SessionSequencesStore,
         isController: Bool,
         metadata: AppMetadata,
         logger: BaseLogger) {
        self.relayer = relay
        self.crypto = crypto
        self.metadata = metadata
        self.wcSubscriber = subscriber
        self.sequencesStore = sequencesStore
        self.isController = isController
        self.logger = logger
        setUpWCRequestHandling()
        restoreSubscriptions()
    }
    
    func approve(proposal: SessionType.Proposal, accounts: Set<String>, completion: @escaping (Result<SessionType.Settled, Error>) -> Void) {
        logger.debug("Approve session")
        let privateKey = Crypto.X25519.generatePrivateKey()
        let selfPublicKey = privateKey.publicKey.toHexString()
        
        let pendingSession = SessionType.Pending(status: .responded,
                                                 topic: proposal.topic,
                                                 relay: proposal.relay,
                                                 self: SessionType.Participant(publicKey: selfPublicKey, metadata: metadata),
                                                 proposal: proposal)
        
        sequencesStore.create(topic: proposal.topic, sequenceState: .pending(pendingSession))
        wcSubscriber.setSubscription(topic: proposal.topic)
        
        let agreementKeys = try! Crypto.X25519.generateAgreementKeys(
            peerPublicKey: Data(hex: proposal.proposer.publicKey),
            privateKey: privateKey)
        let settledTopic = agreementKeys.sharedSecret.sha256().toHexString()
        let sessionState: SessionType.State = SessionType.State(accounts: accounts)
        let expiry = Int(Date().timeIntervalSince1970) + proposal.ttl
        let proposal = pendingSession.proposal
        let controllerKey = proposal.proposer.controller ? proposal.proposer.publicKey : selfPublicKey
        let controller = Controller(publicKey: controllerKey)
        let proposedPermissions = pendingSession.proposal.permissions
        let sessionPermissions = SessionType.Permissions(blockchain: proposedPermissions.blockchain, jsonrpc: proposedPermissions.jsonrpc, notifications: proposedPermissions.notifications, controller: controller)
        let settledSession = SessionType.Settled(
            topic: settledTopic,
            relay: proposal.relay,
            self: SessionType.Participant(publicKey: selfPublicKey, metadata: metadata),
            peer: SessionType.Participant(publicKey: proposal.proposer.publicKey, metadata: proposal.proposer.metadata),
            permissions: sessionPermissions,
            expiry: expiry,
            state: sessionState)
        
        let approveParams = SessionType.ApproveParams(
            relay: proposal.relay,
            responder: SessionType.Participant(
                publicKey: selfPublicKey,
                metadata: metadata),
            expiry: expiry,
            state: sessionState)
        let approvalPayload = ClientSynchJSONRPC(method: .sessionApprove, params: .sessionApprove(approveParams))
        relayer.request(topic: proposal.topic, payload: approvalPayload) { [weak self] result in
            switch result {
            case .success:
                self?.crypto.set(agreementKeys: agreementKeys, topic: settledTopic)
                self?.crypto.set(privateKey: privateKey)
                self?.sequencesStore.update(topic: proposal.topic, newTopic: settledTopic, sequenceState: .settled(settledSession))
                self?.wcSubscriber.setSubscription(topic: settledTopic)
                self?.logger.debug("Success on wc_sessionApprove, published on topic: \(proposal.topic), settled topic: \(settledTopic)")
                completion(.success(settledSession))
            case .failure(let error):
                self?.logger.error(error)
                completion(.failure(error))
            }
        }
    }
    
    func reject(proposal: SessionType.Proposal, reason: SessionType.Reason) {
        let rejectParams = SessionType.RejectParams(reason: reason)
        let rejectPayload = ClientSynchJSONRPC(method: .sessionReject, params: .sessionReject(rejectParams))
        _ = relayer.request(topic: proposal.topic, payload: rejectPayload) { [weak self] result in
            self?.logger.debug("Reject result: \(result)")
        }
    }
    
    func delete(topic: String, reason: SessionType.Reason) {
        logger.debug("Will delete session for reason: message: \(reason.message) code: \(reason.code)")
        sequencesStore.delete(topic: topic)
        wcSubscriber.removeSubscription(topic: topic)
        let clientSynchParams = ClientSynchJSONRPC.Params.sessionDelete(SessionType.DeleteParams(reason: reason))
        let request = ClientSynchJSONRPC(method: .sessionDelete, params: clientSynchParams)

        _ = relayer.request(topic: topic, payload: request) { [weak self] result in
            self?.logger.debug("Session Delete result: \(result)")
        }
    }
    
    func proposeSession(settledPairing: Pairing, permissions: SessionType.Permissions, relay: RelayProtocolOptions) {
        guard let pendingSessionTopic = generateTopic() else {
            logger.debug("Could not generate topic")
            return
        }
        logger.debug("Propose Session on topic: \(pendingSessionTopic)")
        let privateKey = Crypto.X25519.generatePrivateKey()
        let publicKey = privateKey.publicKey.toHexString()
        crypto.set(privateKey: privateKey)
        let proposer = SessionType.Proposer(publicKey: publicKey, controller: isController, metadata: metadata)
        let signal = SessionType.Signal(method: "pairing", params: SessionType.Signal.Params(topic: settledPairing.topic))
        let proposal = SessionType.Proposal(topic: pendingSessionTopic, relay: relay, proposer: proposer, signal: signal, permissions: permissions, ttl: getDefaultTTL())
        let selfParticipant = SessionType.Participant(publicKey: publicKey, metadata: metadata)
        let pending = SessionType.Pending(status: .proposed, topic: pendingSessionTopic, relay: relay, self: selfParticipant, proposal: proposal)
        sequencesStore.create(topic: pendingSessionTopic, sequenceState: .pending(pending))
        wcSubscriber.setSubscription(topic: pendingSessionTopic)
        let request = PairingType.PayloadParams.Request(method: .sessionPropose, params: proposal)
        let pairingPayloadParams = PairingType.PayloadParams(request: request)
        let pairingPayloadRequest = ClientSynchJSONRPC(method: .pairingPayload, params: .pairingPayload(pairingPayloadParams))
        relayer.request(topic: settledPairing.topic, payload: pairingPayloadRequest) { [unowned self] result in
            switch result {
            case .success:
                logger.debug("Session Proposal response received")
                let pairingAgreementKeys = crypto.getAgreementKeys(for: settledPairing.topic)!
                crypto.set(agreementKeys: pairingAgreementKeys, topic: proposal.topic)
            case .failure(let error):
                logger.debug("Could not send session proposal error: \(error)")
            }
        }
    }
    
    func ping(topic: String, completion: @escaping ((Result<Void, Error>) -> ())) {
        guard let _ = sequencesStore.get(topic: topic) else {
            logger.debug("Could not find session to ping for topic \(topic)")
            return
        }
        let request = ClientSynchJSONRPC(method: .sessionPing, params: .sessionPing(SessionType.PingParams()))
        relayer.request(topic: topic, payload: request) { [unowned self] result in
            switch result {
            case .success(_):
                logger.debug("Did receive ping response")
                completion(.success(()))
            case .failure(let error):
                logger.debug("error: \(error)")
            }
        }
    }
    
    func request(params: SessionType.PayloadRequestParams, completion: @escaping ((Result<JSONRPCResponse<AnyCodable>, Error>)->())) {
        guard let _ = sequencesStore.get(topic: params.topic) else {
            logger.debug("Could not find session for topic \(params.topic)")
            return
        }
        let request = SessionType.PayloadParams.Request(method: params.method, params: AnyCodable(params.params))
        let sessionPayloadParams = SessionType.PayloadParams(request: request, chainId: params.chainId)
        let sessionPayloadRequest = ClientSynchJSONRPC(method: .sessionPayload, params: .sessionPayload(sessionPayloadParams))

        relayer.request(topic: params.topic, payload: sessionPayloadRequest) { [weak self] result in
            switch result {
            case .success(let response):
                completion(.success(response))
                self?.logger.debug("Did receive session payload response")
            case .failure(let error):
                self?.logger.debug("error: \(error)")
            }
        }
    }
    
    func respondSessionPayload(topic: String, response: JSONRPCResponse<AnyCodable>) {
        guard let _ = sequencesStore.get(topic: topic) else {
            logger.debug("Could not find session for topic \(topic)")
            return
        }
<<<<<<< HEAD
        relayer.respond(topic: topic, payload: response) { [weak self] error in
            if let error = error {
                self?.logger.debug("Could not send session payload, error: \(error.localizedDescription)")
=======
        relayer.respond(topic: topic, response: JsonRpcResponseTypes.response(response)) { [weak self] error in
            if error != nil {
                self?.logger.debug("Could not send session payload, error: \(error)")
>>>>>>> 26c9a66 (savepoint)
            } else {
                self?.logger.debug("Sent Session Payload Response")
            }
        }
    }
    
    func update(topic: String, accounts: Set<String>) {
        guard case var .settled(session) = sequencesStore.get(topic: topic) else {
            logger.debug("Could not find session for topic \(topic)")
            return
        }
        session.state.accounts = accounts
        let params = ClientSynchJSONRPC.Params.sessionUpdate(SessionType.UpdateParams(state: SessionType.State(accounts: session.state.accounts)))
        let request = ClientSynchJSONRPC(method: .sessionUpdate, params: params)
        relayer.request(topic: topic, payload: request) { [unowned self] result in
            switch result {
            case .success(_):
                sequencesStore.update(topic: topic, newTopic: nil, sequenceState: .settled(session))
                onSessionUpdate?(topic, session.state.accounts)
            case .failure(_):
                break
            }
        }
    }
    
    func upgrade(topic: String, permissions: SessionPermissions) {
        guard case var .settled(session) = sequencesStore.get(topic: topic) else {
            logger.debug("Could not find session for topic \(topic)")
            return
        }
        session.permissions.upgrade(with: permissions)
        let params = SessionType.UpgradeParams(permissions: session.permissions)
        let request = ClientSynchJSONRPC(method: .sessionUpgrade, params: .sessionUpgrade(params))
        relayer.request(topic: topic, payload: request) { [unowned self] result in
            switch result {
            case .success(_):
                sequencesStore.update(topic: topic, newTopic: nil, sequenceState: .settled(session))
                onSessionUpgrade?(session.topic, session.permissions)
            case .failure(_):
                return
                //TODO
            }
        }
    }
    
    func notify(topic: String, params: SessionType.NotificationParams, completion: ((Error?)->())?) {
        guard case .settled(let settledSession) = sequencesStore.get(topic: topic) else {
            logger.debug("Could not find session for topic \(topic)")
            return
        }
        do {
            try validateNotification(session: settledSession, params: params)
            let request = ClientSynchJSONRPC(method: .sessionNotification, params: .sessionNotification(params))
            relayer.request(topic: topic, payload: request) {  result in
                switch result {
                case .success(_):
                    completion?(nil)
                case .failure(let error):
                    completion?(error)
                }
            }
        } catch let error as WalletConnectError {
            logger.error(error)
            completion?(error)
        } catch {}
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
            logger.debug("Problem generating random bytes")
            return nil
        }
    }
    
    private func getDefaultPermissions() -> PairingType.ProposedPermissions {
        PairingType.ProposedPermissions(jsonrpc: PairingType.JSONRPC(methods: [PairingType.PayloadMethods.sessionPropose.rawValue]))
    }
    
    private func setUpWCRequestHandling() {
        wcSubscriber.onRequestSubscription = { [unowned self] subscriptionPayload in
            let requestId = subscriptionPayload.clientSynchJsonRpc.id
            let topic = subscriptionPayload.topic
            switch subscriptionPayload.clientSynchJsonRpc.params {
            case .sessionApprove(let approveParams):
                handleSessionApprove(approveParams, topic: topic, requestId: requestId)
            case .sessionReject(let rejectParams):
                handleSessionReject(rejectParams, topic: topic)
            case .sessionUpdate(let updateParams):
                handleSessionUpdate(topic: topic, updateParams: updateParams, requestId: requestId)
            case .sessionUpgrade(let upgradeParams):
                handleSessionUpgrade(topic: topic, upgradeParams: upgradeParams, requestId: requestId)
            case .sessionDelete(let deleteParams):
                handleSessionDelete(deleteParams, topic: topic)
            case .sessionPayload(let sessionPayloadParams):
                handleSessionPayload(payloadParams: sessionPayloadParams, topic: topic, requestId: requestId)
            case .sessionPing(_):
                handleSessionPing(topic: topic, requestId: requestId)
            case .sessionNotification(let notificationParams):
                handleSessionNotification(topic: topic, notificationParams: notificationParams, requestId: requestId)
            default:
                fatalError("unexpected method type")
            }
        }
    }
    
    private func handleSessionNotification(topic: String, notificationParams: SessionType.NotificationParams, requestId: Int64) {
        guard case .settled(let session) = sequencesStore.get(topic: topic) else {
            return
        }
        do {
            try validateNotification(session: session, params: notificationParams)
            let response = JSONRPCResponse<AnyCodable>(id: requestId, result: AnyCodable(true))
            relayer.respond(topic: topic, response: JsonRpcResponseTypes.response(response)) { [unowned self] error in
                if let error = error {
                    logger.error(error)
                } else {
                    onNotificationReceived?(topic, notificationParams)
                }
            }
        } catch let error as WalletConnectError {
            logger.error(error)
            respond(error: error, requestId: requestId, topic: topic)
            //on unauthorized notification received?
        } catch {}
    }
    
    private func validateNotification(session: SessionType.Settled, params: SessionType.NotificationParams) throws {
        if session.isController {
            return
        } else {
            guard let notifications = session.permissions.notifications,
                  notifications.types.contains(params.type) else {
                throw WalletConnectError.unauthrorized(.unauthorizedNotificationType)
            }
        }
    }
    
    private func handleSessionUpdate(topic: String, updateParams: SessionType.UpdateParams, requestId: Int64) {
        guard case .settled(var session) = sequencesStore.get(topic: topic) else {
            logger.debug("Could not find session for topic \(topic)")
            return
        }
        guard let controller = session.permissions.controller,
        session.peer.publicKey == controller.publicKey else {
            let error = WalletConnectError.unauthrorized(.unauthorizedUpdateRequest)
            logger.error(error)
            respond(error: error, requestId: requestId, topic: topic)
            return
        }
        let response = JSONRPCResponse<AnyCodable>(id: requestId, result: AnyCodable(true))
        relayer.respond(topic: topic, response: JsonRpcResponseTypes.response(response)) { [unowned self] error in
            if let error = error {
                logger.error(error)
            } else {
                session.state = updateParams.state
                sequencesStore.update(topic: topic, newTopic: nil, sequenceState: .settled(session))
                onSessionUpdate?(topic, session.state.accounts)
            }
        }
    }
    
    private func handleSessionUpgrade(topic: String, upgradeParams: SessionType.UpgradeParams, requestId: Int64) {
        guard case .settled(var session) = sequencesStore.get(topic: topic) else {
            logger.debug("Could not find session for topic \(topic)")
            return
        }
        guard let controller = session.permissions.controller,
        session.peer.publicKey == controller.publicKey else {
            let error = WalletConnectError.unauthrorized(.unauthorizedUpgradeRequest)
            logger.error(error)
            respond(error: error, requestId: requestId, topic: topic)
            return
        }
        session.permissions = upgradeParams.permissions
        let response = JSONRPCResponse<AnyCodable>(id: requestId, result: AnyCodable(true))
        relayer.respond(topic: topic, response: JsonRpcResponseTypes.response(response)) { [unowned self] error in
            if let error = error {
                logger.error(error)
            } else {
                sequencesStore.update(topic: topic, newTopic: nil, sequenceState: .settled(session))
                onSessionUpgrade?(session.topic, session.permissions)
            }
        }
    }
    
    private func handleSessionPing(topic: String, requestId: Int64) {
        let response = JSONRPCResponse<AnyCodable>(id: requestId, result: AnyCodable(true))
        relayer.respond(topic: topic, response: .response(response)) { error in
            //todo
        }
    }
    
    private func handleSessionDelete(_ deleteParams: SessionType.DeleteParams, topic: String) {
        guard let _ = sequencesStore.get(topic: topic) else {
            logger.debug("Could not find session for topic \(topic)")
            return
        }
        sequencesStore.delete(topic: topic)
        wcSubscriber.removeSubscription(topic: topic)
        onSessionDelete?(topic, deleteParams.reason)
    }
    
    private func handleSessionReject(_ rejectParams: SessionType.RejectParams, topic: String) {
        guard let _ = sequencesStore.get(topic: topic) else {
            logger.debug("Could not find session for topic \(topic)")
            return
        }
        sequencesStore.delete(topic: topic)
        wcSubscriber.removeSubscription(topic: topic)
        onSessionRejected?(topic, rejectParams.reason)
    }
    
    private func handleSessionPayload(payloadParams: SessionType.PayloadParams, topic: String, requestId: Int64) {
        let jsonRpcRequest = JSONRPCRequest<AnyCodable>(id: requestId, method: payloadParams.request.method, params: payloadParams.request.params)
        let sessionRequest = SessionRequest(topic: topic, request: jsonRpcRequest, chainId: payloadParams.chainId)
        do {
            try validatePayload(sessionRequest)
            onSessionPayloadRequest?(sessionRequest)
        } catch let error as WalletConnectError {
            logger.error(error)
            respond(error: error, requestId: jsonRpcRequest.id, topic: topic)
        } catch {}
    }
    
    private func respond(error: WalletConnectError, requestId: Int64, topic: String) {
        let jsonrpcError = JSONRPCErrorResponse.Error(code: error.code, message: error.description)
        let response = JSONRPCErrorResponse(id: requestId, error: jsonrpcError)
        relayer.respond(topic: topic, response: JsonRpcResponseTypes.error(response)) { [weak self] responseError in
            if let responseError = responseError {
                self?.logger.error("Could not respond with error: \(responseError)")
            } else {
                self?.logger.debug("successfully responded with error")
            }
        }
    }

    private func validatePayload(_ sessionRequest: SessionRequest) throws {
        guard case .settled(let settledSession) = sequencesStore.get(topic: sessionRequest.topic) else {
            throw WalletConnectError.internal(.noSequenceForTopic)
        }
        if let chainId = sessionRequest.chainId {
            guard settledSession.permissions.blockchain.chains.contains(chainId) else {
                throw WalletConnectError.unauthrorized(.unauthorizedJsonRpcMethod)
            }
        }
        guard settledSession.permissions.jsonrpc.methods.contains(sessionRequest.request.method) else {
            throw WalletConnectError.unauthrorized(.unauthorizedJsonRpcMethod)
        }
    }
    
    private func handleSessionApprove(_ approveParams: SessionType.ApproveParams, topic: String, requestId: Int64) {
        logger.debug("Responder Client approved session on topic: \(topic)")
        guard case let .pending(pendingSession) = sequencesStore.get(topic: topic) else {
                  logger.error("Could not find pending session for topic: \(topic)")
            return
        }
        let selfPublicKey = Data(hex: pendingSession.`self`.publicKey)
        logger.debug("handleSessionApprove")
        let privateKey = try! crypto.getPrivateKey(for: selfPublicKey)!
        let peerPublicKey = Data(hex: approveParams.responder.publicKey)
        let agreementKeys = try! Crypto.X25519.generateAgreementKeys(peerPublicKey: peerPublicKey, privateKey: privateKey)
        let settledTopic = agreementKeys.sharedSecret.sha256().toHexString()
        crypto.set(agreementKeys: agreementKeys, topic: settledTopic)
        let proposal = pendingSession.proposal
        let controllerKey = proposal.proposer.controller ? proposal.proposer.publicKey : approveParams.responder.publicKey
        let controller = Controller(publicKey: controllerKey)
        let proposedPermissions = pendingSession.proposal.permissions
        let sessionPermissions = SessionType.Permissions(blockchain: proposedPermissions.blockchain, jsonrpc: proposedPermissions.jsonrpc, notifications: proposedPermissions.notifications, controller: controller)
        
        let settledSession = SessionType.Settled(
            topic: settledTopic,
            relay: approveParams.relay,
            self: SessionType.Participant(publicKey: selfPublicKey.toHexString(), metadata: metadata),
            peer: SessionType.Participant(publicKey: approveParams.responder.publicKey, metadata: approveParams.responder.metadata),
            permissions: sessionPermissions,
            expiry: approveParams.expiry,
            state: approveParams.state)
        sequencesStore.update(topic: proposal.topic, newTopic: settledTopic, sequenceState: .settled(settledSession))
        wcSubscriber.setSubscription(topic: settledTopic)
        wcSubscriber.removeSubscription(topic: proposal.topic)
        let response = JSONRPCResponse<AnyCodable>(id: requestId, result: AnyCodable(true))
        relayer.respond(topic: topic, response: JsonRpcResponseTypes.response(response)) { error in
            if let error = error {
                logger.error(error)
            }
        }
        onSessionApproved?(settledSession)
    }
    
    private func restoreSubscriptions() {
        relayer.transportConnectionPublisher
            .sink { [unowned self] (_) in
                let topics = sequencesStore.getAll().map{$0.topic}
                topics.forEach{self.wcSubscriber.setSubscription(topic: $0)}
            }.store(in: &publishers)
    }
}
