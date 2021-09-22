import Foundation

final class SessionEngine {
    
    let sequences: Sequences<Session>
    private let wcSubscriber: WCSubscribing
    private let relayer: Relaying
    private let crypto: Crypto
    
    init(relay: Relaying,
         crypto: Crypto,
         subscriber: WCSubscribing) {
        self.relayer = relay
        self.crypto = crypto
        self.wcSubscriber = subscriber
        self.sequences = Sequences<Session>()
    }
    
    func approve(proposal: SessionType.Proposal, completion: @escaping (Result<SessionType.Settled, Error>) -> Void) {
        
        let privateKey = Crypto.X25519.generatePrivateKey()
        let selfPublicKey = privateKey.publicKey.toHexString()
        
        let pendingSession = Session.Pending()
        
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
            permissions: SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: []), notifications: SessionType.Notifications(types: []), controller: Controller(publicKey: selfPublicKey)),
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
                print("Success on wc_sessionApprove")
                completion(.success(settledSession))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func reject(proposal: SessionType.Proposal, reason: String) {
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
}
