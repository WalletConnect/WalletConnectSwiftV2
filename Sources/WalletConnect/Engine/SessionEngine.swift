import Foundation
import Combine
import WalletConnectUtils

final class SessionEngine {
    
    var onSessionPayloadRequest: ((SessionRequest)->())?
    var onSessionApproved: ((Session)->())?
    var onApprovalAcknowledgement: ((Session) -> Void)?
    var onSessionRejected: ((String, SessionType.Reason)->())?
    var onSessionUpdate: ((String, Set<String>)->())?
    var onSessionUpgrade: ((String, SessionType.Permissions)->())?
    var onSessionDelete: ((String, SessionType.Reason)->())?
    var onNotificationReceived: ((String, SessionType.NotificationParams)->())?
    
    private let sequencesStore: SessionSequenceStorage
    private let wcSubscriber: WCSubscribing
    private let relayer: WalletConnectRelaying
    private let crypto: CryptoStorageProtocol
    private var isController: Bool
    private var metadata: AppMetadata
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging
    private let topicInitializer: () -> String?

    init(relay: WalletConnectRelaying,
         crypto: CryptoStorageProtocol,
         subscriber: WCSubscribing,
         sequencesStore: SessionSequenceStorage,
         isController: Bool,
         metadata: AppMetadata,
         logger: ConsoleLogging,
         topicGenerator: @escaping () -> String? = String.generateTopic) {
        self.relayer = relay
        self.crypto = crypto
        self.metadata = metadata
        self.wcSubscriber = subscriber
        self.sequencesStore = sequencesStore
        self.isController = isController
        self.logger = logger
        self.topicInitializer = topicGenerator
        setUpWCRequestHandling()
        setupExpirationHandling()
        restoreSubscriptions()
        
        relayer.onResponse = { [weak self] in
            self?.handleReponse($0)
        }
    }
    
    func hasSession(for topic: String) -> Bool {
        return sequencesStore.hasSequence(forTopic: topic)
    }
    
    func getSettledSessions() -> [Session] {
        sequencesStore.getAll().compactMap {
            guard let settled = $0.settled else { return nil }
            let permissions = SessionPermissions(blockchains: settled.permissions.blockchain.chains, methods: settled.permissions.jsonrpc.methods)
            return Session(topic: $0.topic, peer: settled.peer.metadata, permissions: permissions)
        }
    }
    
    func proposeSession(settledPairing: Pairing, permissions: SessionType.Permissions, relay: RelayProtocolOptions) {
        guard let pendingSessionTopic = topicInitializer() else {
            logger.debug("Could not generate topic")
            return
        }
        logger.debug("Propose Session on topic: \(pendingSessionTopic)")
        
        let privateKey = crypto.generatePrivateKey()
        let publicKey = privateKey.publicKey.toHexString()
        
        let proposer = SessionType.Proposer(publicKey: publicKey, controller: isController, metadata: metadata)
        let signal = SessionType.Signal(method: "pairing", params: SessionType.Signal.Params(topic: settledPairing.topic))
        
        let proposal = SessionType.Proposal(
            topic: pendingSessionTopic,
            relay: relay,
            proposer: proposer,
            signal: signal,
            permissions: permissions,
            ttl: SessionSequence.timeToLivePending)
        
        let selfParticipant = SessionType.Participant(publicKey: publicKey, metadata: metadata)
        
        let pendingSession = SessionSequence(
            topic: pendingSessionTopic,
            relay: relay,
            selfParticipant: selfParticipant,
            expiryDate: Date(timeIntervalSinceNow: TimeInterval(Time.day)),
            pendingState: SessionSequence.Pending(status: .proposed, proposal: proposal, outcomeTopic: nil))
        
        crypto.set(privateKey: privateKey)
        sequencesStore.setSequence(pendingSession)
        wcSubscriber.setSubscription(topic: pendingSessionTopic)
        let pairingAgreementKeys = crypto.getAgreementKeys(for: settledPairing.topic)!
        crypto.set(agreementKeys: pairingAgreementKeys, topic: proposal.topic)
        
        let request = PairingType.PayloadParams.Request(method: .sessionPropose, params: proposal)
        let pairingPayloadParams = PairingType.PayloadParams(request: request)
        let pairingPayloadRequest = WCRequest(method: .pairingPayload, params: .pairingPayload(pairingPayloadParams))
        relayer.request(topic: settledPairing.topic, payload: pairingPayloadRequest) { [unowned self] result in
            switch result {
            case .success:
                logger.debug("Session Proposal response received")
            case .failure(let error):
                logger.debug("Could not send session proposal error: \(error)")
            }
        }
    }
    
    func approve(proposal: SessionType.Proposal, accounts: Set<String>, completion: @escaping (Result<Session, Error>) -> Void) {
        logger.debug("Approve session")
        let privateKey = crypto.generatePrivateKey()
        let selfPublicKey = privateKey.publicKey.toHexString()
        
        let agreementKeys = try! Crypto.X25519.generateAgreementKeys(
            peerPublicKey: Data(hex: proposal.proposer.publicKey),
            privateKey: privateKey)
        let settledTopic = agreementKeys.sharedSecret.sha256().toHexString()
        
        let pending = SessionSequence.Pending(
            status: .responded,
            proposal: proposal,
            outcomeTopic: settledTopic)
        let pendingSession = SessionSequence(
            topic: proposal.topic,
            relay: proposal.relay,
            selfParticipant: SessionType.Participant(publicKey: selfPublicKey, metadata: metadata),
            expiryDate: Date(timeIntervalSinceNow: TimeInterval(Time.day)),
            pendingState: pending)
        
        let sessionState: SessionType.State = SessionType.State(accounts: accounts)
        let expiry = Int(Date().timeIntervalSince1970) + proposal.ttl
        let controllerKey = proposal.proposer.controller ? proposal.proposer.publicKey : selfPublicKey
        let controller = Controller(publicKey: controllerKey)
        let proposedPermissions = proposal.permissions
        let sessionPermissions = SessionType.Permissions(blockchain: proposedPermissions.blockchain, jsonrpc: proposedPermissions.jsonrpc, notifications: proposedPermissions.notifications, controller: controller)
        
        let settled = SessionSequence.Settled(
            peer: SessionType.Participant(publicKey: proposal.proposer.publicKey, metadata: proposal.proposer.metadata),
            permissions: sessionPermissions,
            state: sessionState)
        let settledSession = SessionSequence(
            topic: settledTopic,
            relay: proposal.relay,
            selfParticipant: SessionType.Participant(publicKey: selfPublicKey, metadata: metadata),
            expiryDate: Date(timeIntervalSinceNow: TimeInterval(proposal.ttl)),
            settledState: settled)
        
        let approveParams = SessionType.ApproveParams(
            relay: proposal.relay,
            responder: SessionType.Participant(
                publicKey: selfPublicKey,
                metadata: metadata),
            expiry: expiry,
            state: sessionState)
        let approvalPayload = WCRequest(method: .sessionApprove, params: .sessionApprove(approveParams))
        
        sequencesStore.setSequence(pendingSession)
        wcSubscriber.setSubscription(topic: proposal.topic)
        
        crypto.set(privateKey: privateKey)
        crypto.set(agreementKeys: agreementKeys, topic: settledTopic)
        sequencesStore.setSequence(settledSession)
//        sequencesStore.delete(topic: proposal.topic)
        wcSubscriber.setSubscription(topic: settledTopic)
        
        relayer.request(topic: proposal.topic, payload: approvalPayload) { [weak self] result in
            switch result {
            case .success:
//                self?.wcSubscriber.removeSubscription(topic: proposal.topic)
                self?.logger.debug("Success on wc_sessionApprove, published on topic: \(proposal.topic), settled topic: \(settledTopic)")
//                let sessionSuccess = Session(
//                    topic: settledTopic,
//                    peer: proposal.proposer.metadata,
//                    permissions: SessionPermissions(
//                        blockchains: sessionPermissions.blockchain.chains,
//                        methods: sessionPermissions.jsonrpc.methods))
//                completion(.success(sessionSuccess))
            case .failure(let error):
                self?.logger.error(error)
//                completion(.failure(error))
            }
        }
    }
    
    func reject(proposal: SessionType.Proposal, reason: SessionType.Reason) {
        let rejectParams = SessionType.RejectParams(reason: reason)
        let rejectPayload = WCRequest(method: .sessionReject, params: .sessionReject(rejectParams))
        _ = relayer.request(topic: proposal.topic, payload: rejectPayload) { [weak self] result in
            self?.logger.debug("Reject result: \(result)")
        }
    }
    
    func delete(topic: String, reason: SessionType.Reason) {
        logger.debug("Will delete session for reason: message: \(reason.message) code: \(reason.code)")
        sequencesStore.delete(topic: topic)
        wcSubscriber.removeSubscription(topic: topic)
        let params = WCRequest.Params.sessionDelete(SessionType.DeleteParams(reason: reason))
        let request = WCRequest(method: .sessionDelete, params: params)

        _ = relayer.request(topic: topic, payload: request) { [weak self] result in
            self?.logger.debug("Session Delete result: \(result)")
        }
    }
    
    func ping(topic: String, completion: @escaping ((Result<Void, Error>) -> ())) {
        guard sequencesStore.hasSequence(forTopic: topic) else {
            logger.debug("Could not find session to ping for topic \(topic)")
            return
        }
        let request = WCRequest(method: .sessionPing, params: .sessionPing(SessionType.PingParams()))
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
    
    func request(params: SessionType.PayloadRequestParams, completion: @escaping ((Result<JSONRPCResponse<AnyCodable>, JSONRPCErrorResponse>)->())) {
        guard sequencesStore.hasSequence(forTopic: params.topic) else {
            logger.debug("Could not find session for topic \(params.topic)")
            return
        }
        let request = SessionType.PayloadParams.Request(method: params.method, params: params.params)
        let sessionPayloadParams = SessionType.PayloadParams(request: request, chainId: params.chainId)
        let sessionPayloadRequest = WCRequest(method: .sessionPayload, params: .sessionPayload(sessionPayloadParams))
        relayer.request(topic: params.topic, payload: sessionPayloadRequest) { [weak self] result in
            switch result {
            case .success(let response):
                completion(.success(response))
                self?.logger.debug("Did receive session payload response")
            case .failure(let error):
                self?.logger.debug("error: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    func respondSessionPayload(topic: String, response: JsonRpcResponseTypes) {
        guard sequencesStore.hasSequence(forTopic: topic) else {
            logger.debug("Could not find session for topic \(topic)")
            return
        }
        relayer.respond(topic: topic, response: response) { [weak self] error in
            if let error = error {
                self?.logger.debug("Could not send session payload, error: \(error.localizedDescription)")
            } else {
                self?.logger.debug("Sent Session Payload Response")
            }
        }
    }
    
    func update(topic: String, accounts: Set<String>) {
        guard var session = try? sequencesStore.getSequence(forTopic: topic) else {
            logger.debug("Could not find session for topic \(topic)")
            return
        }
        session.update(accounts)
        let params = WCRequest.Params.sessionUpdate(SessionType.UpdateParams(state: SessionType.State(accounts: accounts)))
        let request = WCRequest(method: .sessionUpdate, params: params)
        relayer.request(topic: topic, payload: request) { [unowned self] result in
            switch result {
            case .success(_):
                sequencesStore.setSequence(session)
                onSessionUpdate?(topic, accounts)
            case .failure(_):
                break
            }
        }
    }
    
    func upgrade(topic: String, permissions: SessionPermissions) {
        guard var session = try? sequencesStore.getSequence(forTopic: topic) else {
            logger.debug("Could not find session for topic \(topic)")
            return
        }
        session.upgrade(permissions)
        guard let newPermissions = session.settled?.permissions else {
            return
        }
        let params = SessionType.UpgradeParams(permissions: newPermissions)
        let request = WCRequest(method: .sessionUpgrade, params: .sessionUpgrade(params))
        relayer.request(topic: topic, payload: request) { [unowned self] result in
            switch result {
            case .success(_):
                sequencesStore.setSequence(session)
                onSessionUpgrade?(session.topic, newPermissions)
            case .failure(_):
                return
                //TODO
            }
        }
    }
    
    func notify(topic: String, params: SessionType.NotificationParams, completion: ((Error?)->())?) {
        guard let session = try? sequencesStore.getSequence(forTopic: topic), session.isSettled else {
            logger.debug("Could not find session for topic \(topic)")
            return
        }
        do {
            try validateNotification(session: session, params: params)
            let request = WCRequest(method: .sessionNotification, params: .sessionNotification(params))
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
    
    private func getDefaultPermissions() -> PairingType.ProposedPermissions {
        PairingType.ProposedPermissions(jsonrpc: PairingType.JSONRPC(methods: [PairingType.PayloadMethods.sessionPropose.rawValue]))
    }
    
    private func setUpWCRequestHandling() {
        wcSubscriber.onReceivePayload = { [unowned self] subscriptionPayload in
            let requestId = subscriptionPayload.wcRequest.id
            let topic = subscriptionPayload.topic
            switch subscriptionPayload.wcRequest.params {
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
                logger.warn("Warning: Session Engine - Unexpected method type: \(subscriptionPayload.wcRequest.method) received from subscriber")
            }
        }
    }
    
    private func handleSessionNotification(topic: String, notificationParams: SessionType.NotificationParams, requestId: Int64) {
        guard let session = try? sequencesStore.getSequence(forTopic: topic), session.isSettled else {
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
    
    private func validateNotification(session: SessionSequence, params: SessionType.NotificationParams) throws {
        if session.isController {
            return
        } else {
            guard let notifications = session.settled?.permissions.notifications,
                  notifications.types.contains(params.type) else {
                throw WalletConnectError.unauthrorized(.unauthorizedNotificationType)
            }
        }
    }
    
    private func handleSessionUpdate(topic: String, updateParams: SessionType.UpdateParams, requestId: Int64) {
        guard var session = try? sequencesStore.getSequence(forTopic: topic) else {
            logger.debug("Could not find session for topic \(topic)")
            return
        }
        guard session.peerIsController else {
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
                session.settled?.state = updateParams.state
                sequencesStore.setSequence(session)
                onSessionUpdate?(topic, updateParams.state.accounts)
            }
        }
    }
    
    private func handleSessionUpgrade(topic: String, upgradeParams: SessionType.UpgradeParams, requestId: Int64) {
        guard var session = try? sequencesStore.getSequence(forTopic: topic) else {
            logger.debug("Could not find session for topic \(topic)")
            return
        }
        guard session.peerIsController else {
            let error = WalletConnectError.unauthrorized(.unauthorizedUpgradeRequest)
            logger.error(error)
            respond(error: error, requestId: requestId, topic: topic)
            return
        }
        let permissions = SessionPermissions(
            blockchains: upgradeParams.permissions.blockchain.chains,
            methods: upgradeParams.permissions.jsonrpc.methods)
        session.upgrade(permissions)
        guard let newPermissions = session.settled?.permissions else {
            return
        }
        let response = JSONRPCResponse<AnyCodable>(id: requestId, result: AnyCodable(true))
        relayer.respond(topic: topic, response: JsonRpcResponseTypes.response(response)) { [unowned self] error in
            if let error = error {
                logger.error(error)
            } else {
                try? sequencesStore.setSequence(session)
                onSessionUpgrade?(session.topic, newPermissions)
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
        guard sequencesStore.hasSequence(forTopic: topic) else {
            logger.debug("Could not find session for topic \(topic)")
            return
        }
        sequencesStore.delete(topic: topic)
        wcSubscriber.removeSubscription(topic: topic)
        onSessionDelete?(topic, deleteParams.reason)
    }
    
    private func handleSessionReject(_ rejectParams: SessionType.RejectParams, topic: String) {
        guard sequencesStore.hasSequence(forTopic: topic) else {
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
        guard let session = try? sequencesStore.getSequence(forTopic: sessionRequest.topic) else {
            throw WalletConnectError.internal(.noSequenceForTopic)
        }
        if let chainId = sessionRequest.chainId {
            guard session.hasPermission(forChain: chainId) else {
                throw WalletConnectError.unauthrorized(.unauthorizedJsonRpcMethod)
            }
        }
        guard session.hasPermission(forMethod: sessionRequest.request.method) else {
            throw WalletConnectError.unauthrorized(.unauthorizedJsonRpcMethod)
        }
    }
    
    private func handleSessionApprove(_ approveParams: SessionType.ApproveParams, topic: String, requestId: Int64) {
        logger.debug("Responder Client approved session on topic: \(topic)")
        logger.debug("isController: \(isController)")
        guard !isController else {
            logger.warn("Warning: Session Engine - Unexpected handleSessionApprove method call by non Controller client")
            return
        }
        guard let session = try? sequencesStore.getSequence(forTopic: topic),
              let pendingSession = session.pending else {
                  logger.error("Could not find pending session for topic: \(topic)")
                  return
              }
        let selfPublicKey = Data(hex: session.selfParticipant.publicKey)
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
        
        let peer = SessionType.Participant(publicKey: approveParams.responder.publicKey, metadata: approveParams.responder.metadata)
        let settledSession = SessionSequence(
            topic: settledTopic,
            relay: approveParams.relay,
            selfParticipant: SessionType.Participant(publicKey: selfPublicKey.toHexString(), metadata: metadata),
            expiryDate: Date(timeIntervalSinceNow: TimeInterval(approveParams.expiry)),
            settledState: SessionSequence.Settled(
                peer: peer,
                permissions: sessionPermissions,
                state: approveParams.state))
        sequencesStore.delete(topic: proposal.topic)
        sequencesStore.setSequence(settledSession)
        
        wcSubscriber.setSubscription(topic: settledTopic)
        wcSubscriber.removeSubscription(topic: proposal.topic)
        
        let approvedSession = Session(
            topic: settledTopic,
            peer: peer.metadata,
            permissions: SessionPermissions(
                blockchains: sessionPermissions.blockchain.chains,
                methods: sessionPermissions.jsonrpc.methods))
        onSessionApproved?(approvedSession)
        
        let response = JSONRPCResponse<AnyCodable>(id: requestId, result: AnyCodable(true))
        relayer.respond(topic: topic, response: JsonRpcResponseTypes.response(response)) { [unowned self] error in
            if let error = error {
                logger.error(error)
            }
        }
    }
    
    private func setupExpirationHandling() {
        sequencesStore.onSequenceExpiration = { [weak self] topic, publicKey in
            self?.crypto.deletePrivateKey(for: publicKey)
            self?.crypto.deleteAgreementKeys(for: topic)
        }
    }
    
    private func restoreSubscriptions() {
        relayer.transportConnectionPublisher
            .sink { [unowned self] (_) in
                let topics = sequencesStore.getAll().map{$0.topic}
                topics.forEach{self.wcSubscriber.setSubscription(topic: $0)}
            }.store(in: &publishers)
    }
    
    private func handleReponse(_ response: WCResponse) {
        switch response.requestParams {
        case .pairingPayload(let payloadParams):
            let proposeParams = payloadParams.request.params
            handleProposeResponse(topic: response.topic, proposeParams: proposeParams, result: response.result)
        case .sessionApprove(let approveParams):
            handleApproveResponse(topic: response.topic, result: response.result)
        default:
            break
        }
    }
    
    private func handleProposeResponse(topic: String, proposeParams: SessionType.Proposal, result: Result<JSONRPCResponse<AnyCodable>, Error>) {
        switch result {
        case .success:
            break
        case .failure:
            wcSubscriber.removeSubscription(topic: proposeParams.topic)
            crypto.deletePrivateKey(for: proposeParams.proposer.publicKey)
            crypto.deleteAgreementKeys(for: topic)
            sequencesStore.delete(topic: proposeParams.topic)
        }
    }
    
    private func handleApproveResponse(topic: String, result: Result<JSONRPCResponse<AnyCodable>, Error>) {
        guard
            let pendingSession = try? sequencesStore.getSequence(forTopic: topic),
            let settledTopic = pendingSession.pending?.outcomeTopic,
            let proposal = pendingSession.pending?.proposal
        else {
            return
        }
        switch result {
        case .success:
            crypto.deleteAgreementKeys(for: topic)
            wcSubscriber.removeSubscription(topic: topic)
            sequencesStore.delete(topic: topic)
            let sessionSuccess = Session(
                topic: settledTopic,
                peer: proposal.proposer.metadata,
                permissions: SessionPermissions(
                    blockchains: proposal.permissions.blockchain.chains,
                    methods: proposal.permissions.jsonrpc.methods))
            onApprovalAcknowledgement?(sessionSuccess)
        case .failure:
            wcSubscriber.removeSubscription(topic: topic)
            wcSubscriber.removeSubscription(topic: settledTopic)
            sequencesStore.delete(topic: topic)
            sequencesStore.delete(topic: settledTopic)
            crypto.deleteAgreementKeys(for: topic)
            crypto.deleteAgreementKeys(for: settledTopic)
            crypto.deletePrivateKey(for: pendingSession.publicKey)
        }
    }
}
