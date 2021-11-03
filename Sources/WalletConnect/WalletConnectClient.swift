
import Foundation

public protocol WalletConnectClientDelegate: AnyObject {
    func didReceive(sessionProposal: SessionProposal)
    func didReceive(sessionRequest: SessionRequest)
    func didSettle(session: Session)
    func didSettle(pairing: PairingType.Settled)
    func didReject(sessionPendingTopic: String, reason: SessionType.Reason)
    func didDelete(sessionTopic: String, reason: SessionType.Reason)
    func didUpgrade(sessionTopic: String, permissions: SessionType.Permissions)
}

public final class WalletConnectClient {
    private let metadata: AppMetadata
    public weak var delegate: WalletConnectClientDelegate?
    let isController: Bool
    let pairingEngine: PairingEngine
    let sessionEngine: SessionEngine
    private let relay: WalletConnectRelaying
    private let crypto = Crypto()
    private var sessionPermissions: [String: SessionType.Permissions] = [:]
    var logger: BaseLogger = ConsoleLogger()
    private let secureStorage = SecureStorage()
    
    // MARK: - Public interface

    public convenience init(metadata: AppMetadata, apiKey: String, isController: Bool, relayURL: URL) {
        self.init(metadata: metadata, apiKey: apiKey, isController: isController, relayURL: relayURL, logger: MuteLogger())
    }
    
    init(metadata: AppMetadata, apiKey: String, isController: Bool, relayURL: URL, logger: BaseLogger = MuteLogger()) {
        self.metadata = metadata
        self.isController = isController
        let wakuRelay = WakuNetworkRelay(transport: JSONRPCTransport(url: relayURL), logger: logger)
        self.relay = WalletConnectRelay(networkRelayer: wakuRelay, crypto: crypto, logger: logger)
        let sessionSequencesStore = SessionUserDefaultsStore(logger: logger)
        let pairingSequencesStore = PairingUserDefaultsStore(logger: logger)
        self.pairingEngine = PairingEngine(relay: relay, crypto: crypto, subscriber: WCSubscriber(relay: relay, logger: logger), sequencesStore: pairingSequencesStore, isController: isController, metadata: metadata, logger: logger)
        self.sessionEngine = SessionEngine(relay: relay, crypto: crypto, subscriber: WCSubscriber(relay: relay, logger: logger), sequencesStore: sessionSequencesStore, isController: isController, metadata: metadata, logger: logger)
        setUpEnginesCallbacks()
        secureStorage.setAPIKey(apiKey)
    }
    
    // for proposer to propose a session to a responder
    public func connect(params: ConnectParams) throws -> String? {
        logger.debug("Connecting Application")
        if let topic = params.pairing?.topic,
           let pairing = pairingEngine.sequencesStore.get(topic: topic) {
            logger.debug("Connecting with existing pairing")
            fatalError("not implemented")
            return nil
        } else {
            guard let pending = pairingEngine.propose(params) else {
                throw WalletConnectError.internal(.pairingProposalGenerationFailed)
            }
            sessionPermissions[pending.topic] = params.permissions
            return pending.proposal.signal.params.uri
        }
    }
    
    // for responder to receive a session proposal from a proposer
    public func pair(uri: String) throws {
        print("start pair")
        guard let pairingURI = WalletConnectURI(string: uri) else {
            throw WalletConnectError.internal(.malformedPairingURI)
        }
        let proposal = PairingType.Proposal.createFromURI(pairingURI)
        let approved = proposal.proposer.controller != isController
        if !approved {
            throw WalletConnectError.internal(.unauthorizedMatchingController)
        }
        pairingEngine.pair(proposal) { [unowned self] result in
            switch result {
            case .success(let settledPairing):
                logger.debug("Pairing Success")
                self.delegate?.didSettle(pairing: settledPairing)
            case .failure(let error):
                print("Pairing Failure: \(error)")
            }
        }
    }
    
    // for responder to approve a session proposal
    public func approve(proposal: SessionProposal, accounts: [String]) {
        sessionEngine.approve(proposal: proposal.proposal, accounts: accounts) { [unowned self] result in
            switch result {
            case .success(let settledSession):
                let session = Session(topic: settledSession.topic, peer: settledSession.peer.metadata)
                self.delegate?.didSettle(session: session)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // for responder to reject a session proposal
    public func reject(proposal: SessionProposal, reason: SessionType.Reason) {
        sessionEngine.reject(proposal: proposal.proposal, reason: reason)
    }
    
    public func upgrade(topic: String, permissions: SessionPermissions) {
        sessionEngine.upgrade(topic: topic, permissions: permissions)
    }
    // TODO: Update methods.
    
    // for proposer to request JSON-RPC
    public func request(params: SessionType.PayloadRequestParams, completion: @escaping (Result<JSONRPCResponse<AnyCodable>, Error>) -> ()) {
        sessionEngine.request(params: params, completion: completion)
    }
    
    // for responder to respond JSON-RPC
    public func respond(topic: String, response: JSONRPCResponse<AnyCodable>) {
        sessionEngine.respondSessionPayload(topic: topic, response: response)
    }
    
    public func ping(topic: String, completion: @escaping ((Result<Void, Error>) -> ())) {
        if pairingEngine.sequencesStore.get(topic: topic) != nil {
            pairingEngine.ping(topic: topic) { result in
                completion(result)
            }
        } else if sessionEngine.sequencesStore.get(topic: topic) != nil {
            sessionEngine.ping(topic: topic) { result in
                completion(result)
            }
        }
    }
    
    // TODO: notification method
    
    // for either to disconnect a session
    public func disconnect(topic: String, reason: SessionType.Reason) {
        sessionEngine.delete(topic: topic, reason: reason)
    }
    
    public func getSettledSessions() -> [Session] {
        let settledSessions = sessionEngine.sequencesStore.getSettled()
        let sessions = settledSessions.map {
            Session(topic: $0.topic, peer: $0.peer.metadata)
        }
        return sessions
    }
    
    public func getSettledPairings() -> [PairingType.Settled] {
        pairingEngine.sequencesStore.getSettled()
    }
    
    //MARK: - Private
    
    private func setUpEnginesCallbacks() {
        pairingEngine.onSessionProposal = { [unowned self] proposal in
            self.proposeSession(proposal: proposal)
        }
        pairingEngine.onPairingApproved = { [unowned self] settledPairing, pendingTopic in
            self.delegate?.didSettle(pairing: settledPairing)
            guard let permissions = sessionPermissions[pendingTopic] else {
                logger.debug("Cound not find permissions for pending topic: \(pendingTopic)")
                return
            }
            sessionPermissions[pendingTopic] = nil
            self.sessionEngine.proposeSession(settledPairing: settledPairing, permissions: permissions)
        }
        sessionEngine.onSessionApproved = { [unowned self] settledSession in
            let session = Session(topic: settledSession.topic, peer: settledSession.peer.metadata)
            self.delegate?.didSettle(session: session)
        }
        sessionEngine.onSessionRejected = { [unowned self] pendingTopic, reason in
            self.delegate?.didReject(sessionPendingTopic: pendingTopic, reason: reason)
        }
        sessionEngine.onSessionPayloadRequest = { [unowned self] sessionRequest in
            self.delegate?.didReceive(sessionRequest: sessionRequest)
        }
        sessionEngine.onSessionDelete = { [unowned self] topic, reason in
            self.delegate?.didDelete(sessionTopic: topic, reason: reason)
        }
        sessionEngine.onSessionUpgrade = { [unowned self] topic, permissions in
            delegate?.didUpgrade(sessionTopic: topic, permissions: permissions)
        }
    }
    
    private func proposeSession(proposal: SessionType.Proposal) {
        let sessionProposal = SessionProposal(
            proposer: proposal.proposer.metadata,
            permissions: SessionPermissions(
                blockchains: proposal.permissions.blockchain.chains,
                methods: proposal.permissions.jsonrpc.methods),
            proposal: proposal
        )
        delegate?.didReceive(sessionProposal: sessionProposal)
    }
}

public struct ConnectParams {
    let permissions: SessionType.Permissions
    let pairing: ParamsPairing?
    
    public init(permissions: SessionType.Permissions, topic: String? = nil) {
        self.permissions = permissions
        if let topic = topic {
            self.pairing = ParamsPairing(topic: topic)
        } else {
            self.pairing = nil
        }
    }
    public struct ParamsPairing {
        let topic: String
    }
}

public struct SessionRequest: Codable, Equatable {
    public let topic: String
    public let request: JSONRPCRequest<AnyCodable>
    public let chainId: String?
}
