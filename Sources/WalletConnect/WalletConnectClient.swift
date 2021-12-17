
import Foundation
import Relayer
import WalletConnectUtils
#if os(iOS)
import UIKit
#endif

extension ConsoleLogger: ConsoleLogging {}
extension WakuNetworkRelay: NetworkRelaying {}

public protocol WalletConnectClientDelegate: AnyObject {
    func didReceive(sessionProposal: SessionProposal)
    func didReceive(sessionRequest: SessionRequest)
    func didDelete(sessionTopic: String, reason: SessionType.Reason)
    func didUpgrade(sessionTopic: String, permissions: SessionType.Permissions)
    func didUpdate(sessionTopic: String, accounts: Set<String>)
    func didSettle(session: Session)
    func didSettle(pairing: Pairing)
    func didReceive(notification: SessionNotification, sessionTopic: String)
    func didReject(pendingSessionTopic: String, reason: SessionType.Reason)
    func didUpdate(pairingTopic: String, appMetadata: AppMetadata)
}

public extension WalletConnectClientDelegate {
    func didSettle(session: Session) {}
    func didSettle(pairing: Pairing) {}
    func didReceive(notification: SessionNotification, sessionTopic: String) {}
    func didReject(pendingSessionTopic: String, reason: SessionType.Reason) {}
    func didUpdate(pairingTopic: String, appMetadata: AppMetadata) {}
}

public final class WalletConnectClient {
    private let metadata: AppMetadata
    public weak var delegate: WalletConnectClientDelegate?
    private let isController: Bool
    private let pairingEngine: PairingEngine
    private let sessionEngine: SessionEngine
    private let relay: WalletConnectRelaying
    private let wakuRelay: NetworkRelaying
    private let crypto: Crypto
    public let logger: ConsoleLogging
    private let secureStorage: SecureStorage
    private let pairingQueue = DispatchQueue(label: "com.walletconnect.sdk.client.pairing", qos: .userInitiated)

    
    // MARK: - Public interface

    public convenience init(metadata: AppMetadata, projectId: String, isController: Bool, relayHost: String, keyValueStorage: KeyValueStorage = UserDefaults.standard, clientName: String? = nil) {
        self.init(metadata: metadata, projectId: projectId, isController: isController, relayHost: relayHost, logger: ConsoleLogger(loggingLevel: .off), keychain: KeychainStorage(uniqueIdentifier: clientName), keyValueStore: keyValueStorage, clientName: clientName)
    }
    
    init(metadata: AppMetadata, projectId: String, isController: Bool, relayHost: String, logger: ConsoleLogging, keychain: KeychainStorage, keyValueStore: KeyValueStorage, clientName: String? = nil) {
        self.metadata = metadata
        self.isController = isController
        self.logger = logger
//        try? keychain.deleteAll() // Use for cleanup while lifecycles are not handled yet, but FIXME whenever
        self.crypto = Crypto(keychain: keychain)
        self.secureStorage = SecureStorage(keychain: keychain)
        let relayUrl = WakuNetworkRelay.makeRelayUrl(host: relayHost, projectId: projectId)
        self.wakuRelay = WakuNetworkRelay(logger: logger, url: relayUrl)
        let serialiser = JSONRPCSerialiser(crypto: crypto)
        self.relay = WalletConnectRelay(networkRelayer: wakuRelay, jsonRpcSerialiser: serialiser, logger: logger, jsonRpcHistory: JsonRpcHistory(logger: logger, keyValueStorage: keyValueStore, uniqueIdentifier: clientName))
        let pairingSequencesStore = PairingStorage(storage: SequenceStore<PairingSequence>(storage: keyValueStore, uniqueIdentifier: clientName))
        let sessionSequencesStore = SessionStorage(storage: SequenceStore<SessionSequence>(storage: keyValueStore, uniqueIdentifier: clientName))
        self.pairingEngine = PairingEngine(relay: relay, crypto: crypto, subscriber: WCSubscriber(relay: relay, logger: logger), sequencesStore: pairingSequencesStore, isController: isController, metadata: metadata, logger: logger)
        self.sessionEngine = SessionEngine(relay: relay, crypto: crypto, subscriber: WCSubscriber(relay: relay, logger: logger), sequencesStore: sessionSequencesStore, isController: isController, metadata: metadata, logger: logger)
        setUpEnginesCallbacks()
        subscribeNotificationCenter()
    }
    
    deinit {
        unsubscribeNotificationCenter()
    }
    
    // for proposer to propose a session to a responder
    public func connect(params: ConnectParams) throws -> String? {
        logger.debug("Connecting Application")
        if let topic = params.pairing?.topic {
            guard let pairing = pairingEngine.getSettledPairing(for: topic) else {
                throw WalletConnectError.InternalReason.noSequenceForTopic
            }
            logger.debug("Proposing session on existing pairing")
            
            sessionEngine.proposeSession(settledPairing: Pairing(topic: pairing.topic, peer: nil), permissions: params.permissions, relay: pairing.relay)
            return nil
        } else {
            guard let pairingURI = pairingEngine.propose(permissions: params.permissions) else {
                throw WalletConnectError.internal(.pairingProposalGenerationFailed)
            }
            return pairingURI.absoluteString
        }
    }
    
    // for responder to receive a session proposal from a proposer
    public func pair(uri: String) throws {
        guard let pairingURI = WalletConnectURI(string: uri) else {
            throw WalletConnectError.internal(.malformedPairingURI)
        }
        try pairingQueue.sync {
            try pairingEngine.approve(pairingURI)
        }
    }
    
    // for responder to approve a session proposal
    public func approve(proposal: SessionProposal, accounts: Set<String>, completion: @escaping (Result<Session, Error>) -> ()) {
        sessionEngine.approve(proposal: proposal.proposal, accounts: accounts) { [unowned self] result in
            switch result {
            case .success(let settledSession):
                let session = Session(topic: settledSession.topic, peer: settledSession.peer, permissions: proposal.permissions)
                self.delegate?.didSettle(session: session)
                completion(.success(session))
            case .failure(let error):
                completion(.failure(error))
                print(error)
            }
        }
    }
    
    // for responder to reject a session proposal
    public func reject(proposal: SessionProposal, reason: SessionType.Reason) {
        sessionEngine.reject(proposal: proposal.proposal, reason: reason)
    }
    
    public func update(topic: String, accounts: Set<String>) {
        sessionEngine.update(topic: topic, accounts: accounts)
    }
    
    public func upgrade(topic: String, permissions: SessionPermissions) {
        sessionEngine.upgrade(topic: topic, permissions: permissions)
    }
    
    // for proposer to request JSON-RPC
    public func request(params: SessionType.PayloadRequestParams, completion: @escaping (Result<JSONRPCResponse<AnyCodable>, JSONRPCErrorResponse>) -> ()) {
        sessionEngine.request(params: params, completion: completion)
    }
    
    // for responder to respond JSON-RPC
    public func respond(topic: String, response: JsonRpcResponseTypes) {
        sessionEngine.respondSessionPayload(topic: topic, response: response)
    }
    
    public func ping(topic: String, completion: @escaping ((Result<Void, Error>) -> ())) {
        if pairingEngine.hasPairing(for: topic) {
            pairingEngine.ping(topic: topic) { result in
                completion(result)
            }
        } else if sessionEngine.hasSession(for: topic) {
            sessionEngine.ping(topic: topic) { result in
                completion(result)
            }
        }
    }
    
    public func notify(topic: String, params: SessionType.NotificationParams, completion: ((Error?)->())?) {
        sessionEngine.notify(topic: topic, params: params, completion: completion)
    }
    
    // for either to disconnect a session
    public func disconnect(topic: String, reason: SessionType.Reason) {
        sessionEngine.delete(topic: topic, reason: reason)
    }
    
    public func getSettledSessions() -> [Session] {
        sessionEngine.getSettledSessions()
    }
    
    public func getSettledPairings() -> [Pairing] {
        pairingEngine.getSettledPairings()
    }
    
    //MARK: - Private
    
    private func setUpEnginesCallbacks() {
        pairingEngine.onSessionProposal = { [unowned self] proposal in
            proposeSession(proposal: proposal)
        }
        pairingEngine.onPairingApproved = { [unowned self] settledPairing, permissions, relayOptions in
            delegate?.didSettle(pairing: settledPairing)
            sessionEngine.proposeSession(settledPairing: settledPairing, permissions: permissions, relay: relayOptions)
        }
        pairingEngine.onApprovalAcknowledgement = { [weak self] settledPairing in
            self?.delegate?.didSettle(pairing: settledPairing)
        }
        sessionEngine.onSessionApproved = { [unowned self] settledSession in
            let permissions = SessionPermissions.init(blockchains: settledSession.permissions.blockchains, methods: settledSession.permissions.methods)
            let session = Session(topic: settledSession.topic, peer: settledSession.peer, permissions: permissions)
            delegate?.didSettle(session: session)
        }
        sessionEngine.onSessionRejected = { [unowned self] pendingTopic, reason in
            delegate?.didReject(pendingSessionTopic: pendingTopic, reason: reason)
        }
        sessionEngine.onSessionPayloadRequest = { [unowned self] sessionRequest in
            delegate?.didReceive(sessionRequest: sessionRequest)
        }
        sessionEngine.onSessionDelete = { [unowned self] topic, reason in
            delegate?.didDelete(sessionTopic: topic, reason: reason)
        }
        sessionEngine.onSessionUpgrade = { [unowned self] topic, permissions in
            delegate?.didUpgrade(sessionTopic: topic, permissions: permissions)
        }
        sessionEngine.onSessionUpdate = { [unowned self] topic, accounts in
            delegate?.didUpdate(sessionTopic: topic, accounts: accounts)
        }
        sessionEngine.onNotificationReceived = { [unowned self] topic, notification in
            delegate?.didReceive(notification: notification, sessionTopic: topic)
        }
        pairingEngine.onPairingUpdate = { [unowned self] topic, appMetadata in
            delegate?.didUpdate(pairingTopic: topic, appMetadata: appMetadata)
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
    
    private func subscribeNotificationCenter() {
#if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
#endif
    }
    
    private func unsubscribeNotificationCenter() {
#if os(iOS)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
#endif
    }
    
    @objc
    private func appWillEnterForeground() {
        wakuRelay.connect()
    }
    
    @objc
    private func appDidEnterBackground() {
        wakuRelay.disconnect(closeCode: .goingAway)
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
