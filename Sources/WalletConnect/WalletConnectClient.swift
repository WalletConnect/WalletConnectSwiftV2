
import Foundation

public final class WalletConnectClient {
    
    private let metadata: AppMetadata
    public weak var delegate: WalletConnectClientDelegate?
    private let isController: Bool
    private let pairingEngine: PairingEngine
    private let sessionEngine: SessionEngine
    private let relay: Relay
    private let crypto = Crypto()
    private var sessionPermissions: [String: SessionType.Permissions] = [:]

    
    // MARK: - Public interface
    public init(options: WalletClientOptions) {
        self.isController = options.isController
        self.metadata = options.metadata
        self.relay = Relay(transport: JSONRPCTransport(url: options.relayURL), crypto: crypto)
        self.pairingEngine = PairingEngine(relay: relay, crypto: crypto, subscriber: WCSubscriber(relay: relay), isController: isController, metadata: metadata)
        self.sessionEngine = SessionEngine(relay: relay, crypto: crypto, subscriber: WCSubscriber(relay: relay), isController: isController, metadata: metadata)
        setUpEnginesCallbacks()
        // TODO: Store api key
    }
    
    // for proposer to propose a session to a responder
    public func connect(params: ConnectParams) throws -> String? {
        Logger.debug("Connecting Application")
        if let topic = params.pairing?.topic,
           let pairing = pairingEngine.sequences.get(topic: topic) {
            Logger.debug("Connecting with existing pairing")
            fatalError("not implemented")
            return nil
        } else {
            guard let pending = pairingEngine.propose(params) else {
                throw WalletConnectError.connection
            }
            sessionPermissions[pending.topic] = params.permissions
            return pending.proposal.signal.params.uri
        }
    }
    
    // for responder to receive a session proposal from a proposer
    public func pair(uri: String, completion: @escaping (Result<String, Error>) -> Void) throws {
        print("start pair")
        guard let pairingURI = PairingType.UriParameters(uri) else {
            throw WalletConnectError.PairingParamsUriInitialization
        }
        let proposal = PairingType.Proposal.createFromURI(pairingURI)
        let approved = proposal.proposer.controller != isController
        if !approved {
            throw WalletConnectError.unauthorizedMatchingController
        }
        pairingEngine.respond(to: proposal) { result in
            switch result {
            case .success:
                print("Pairing Success")
            case .failure(let error):
                print("Pairing Failure: \(error)")
            }
            completion(result)
        }
    }
    
    // for either to disconnect a session
    public func disconnect(params: SessionType.DeleteParams) {
        sessionEngine.delete(params: params)
    }
    
    // for responder to approve a session proposal
    public func approve(proposal: SessionType.Proposal, completion: @escaping ((Result<SessionType.Settled, Error>) -> Void)) {
        sessionEngine.approve(proposal: proposal) { [unowned self] result in
            switch result {
            case .success(let settledSession):
                self.delegate?.didSettleSession(settledSession)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // for proposer to request JSON-RPC
    public func request(params: SessionType.RequestParams) {
        sessionEngine.request(params: params)
    }
    
    // for responder to respond JSON-RPC
    public func respond(params: RespondParams) {
        
    }
    
    // for responder to reject a session proposal
    public func reject(proposal: SessionType.Proposal, reason: SessionType.Reason) {
        sessionEngine.reject(proposal: proposal, reason: reason)
    }
    
    public func getSettledSessions() -> [SessionType.Settled] {
        return sessionEngine.sequences.getSettled() as! [SessionType.Settled]
    }
    
    public func getSettledPairings() -> [PairingType.Settled] {
        pairingEngine.sequences.getSettled() as! [PairingType.Settled]
    }
    
    //MARK: - Private
    
    private func setUpEnginesCallbacks() {
        pairingEngine.onSessionProposal = { [unowned self] proposal in
            self.delegate?.didReceive(sessionProposal: proposal)
        }
        pairingEngine.onPairingApproved = { [unowned self] settledPairing, pendingTopic in
            self.delegate?.didSettlePairing(settledPairing)
            guard let permissions = sessionPermissions[pendingTopic] else {
                Logger.debug("Cound not find permissions for pending topic: \(pendingTopic)")
                return
            }
            sessionPermissions[pendingTopic] = nil
            self.sessionEngine.proposeSession(settledPairing: settledPairing, permissions: permissions)
        }
        sessionEngine.onSessionApproved = { [unowned self] settledSession in
            self.delegate?.didSettleSession(settledSession)
        }
        sessionEngine.onPayload = { [unowned self] sessionPayloadInfo in
            self.delegate?.didReceive(sessionPayload: sessionPayloadInfo)
        }
    }
}

public protocol WalletConnectClientDelegate: AnyObject {
    func didReceive(sessionProposal: SessionType.Proposal)
    func didReceive(sessionPayload: SessionPayloadInfo)
    func didSettleSession(_ sessionSettled: SessionType.Settled)
    func didSettlePairing(_ settledPairing: PairingType.Settled)
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

public struct RespondParams: Codable, Equatable {
    let topic: String
//    let response: String
}

public struct SessionPayloadInfo: Codable, Equatable {
    let params: SessionType.PayloadParams
    let topic: String
    let requestId: Int64
}
