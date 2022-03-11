import Foundation
import WalletConnectKMS

struct Participants: Codable, Equatable {
    let `self`: Participant
    let peer: Participant
}

struct SessionSequence: ExpirableSequence {
    enum Error: Swift.Error {
        case controllerNotSet
    }
    let topic: String
    let relay: RelayProtocolOptions
    let controller: AgreementPeer
    let participants: Participants
    var blockchain: Blockchain
    var permissions: SessionPermissions

    var acknowledged: Bool

    private (set) var expiryDate: Date
    
    static var defaultTimeToLive: Int {
        7*Time.day
    }
    // for expirable...
    var publicKey: String? {
        participants.`self`.publicKey
    }
    
    init(topic: String,
         selfParticipant: Participant,
         peerParticipant: Participant,
         settleParams: SessionType.SettleParams,
         acknowledged: Bool) {
        self.topic = topic
        self.relay = settleParams.relay
        self.controller = AgreementPeer(publicKey: settleParams.controller.publicKey)
        self.participants = Participants(self: selfParticipant, peer: peerParticipant)
        self.blockchain = settleParams.blockchain
        self.permissions = settleParams.permissions
        self.acknowledged = acknowledged
        self.expiryDate = Date(timeIntervalSince1970: settleParams.expiry)
    }
    
    init(topic: String, relay: RelayProtocolOptions, controller: AgreementPeer, participants: Participants, blockchain: Blockchain, permissions: SessionPermissions, acknowledged: Bool) {
        self.topic = topic
        self.relay = relay
        self.controller = controller
        self.participants = participants
        self.blockchain = blockchain
        self.permissions = permissions
        self.acknowledged = acknowledged
        self.expiryDate = Date.distantFuture
    }
    
    mutating func acknowledge() {
        self.acknowledged = true
    }
    
    
    func getPublicKey() throws -> AgreementPublicKey {
        try AgreementPublicKey(rawRepresentation: Data(hex: participants.`self`.publicKey))
    }
    
    var selfIsController: Bool {
        return controller.publicKey == participants.`self`.publicKey
    }
    
    var peerIsController: Bool {
        return controller.publicKey == participants.peer.publicKey
    }
    
    func hasPermission(forChain chainId: String) -> Bool {
        return blockchain.chains.contains(chainId)
    }
    
    func hasPermission(forMethod method: String) -> Bool {
        return permissions.jsonrpc.methods.contains(method)
    }
    
    func hasPermission(forNotification type: String) -> Bool {
        guard let notificationPermissions = permissions.notifications else { return false }
        return notificationPermissions.types.contains(type)
    }
    
    mutating func upgrade(_ permissions: SessionPermissions) {
        self.permissions.upgrade(with: permissions)
    }
    
    mutating func update(_ accounts: Set<Account>) {
        //todo - handle chains and accounts
        blockchain.accounts = accounts
    }
    
    mutating func extend(_ ttl: Int) throws {
        let newExpiryDate = Date(timeIntervalSinceNow: TimeInterval(ttl))
        let maxExpiryDate = Date(timeIntervalSinceNow: TimeInterval(SessionSequence.defaultTimeToLive))
        guard newExpiryDate > expiryDate && newExpiryDate <= maxExpiryDate else {
            throw WalletConnectError.invalidExtendTime
        }
        expiryDate = newExpiryDate
    }

    func publicRepresentation() -> Session {
        return Session(
            topic: topic,
            peer: participants.peer.metadata,
            permissions: Session.Permissions(methods: permissions.jsonrpc.methods),
            accounts: blockchain.accounts,
            expiryDate: expiryDate,
            blockchains: blockchain.chains)
    }
}
