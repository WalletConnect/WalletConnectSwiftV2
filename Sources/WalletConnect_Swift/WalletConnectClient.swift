// 

import Foundation
import CryptoKit
import CryptoSwift

public class DebugClient {
    let relay: Relay
    let crypto: Crypto
    public init(relayUrl: URL = URL(string: "wss://relay.walletconnect.org/?protocol=wc&version=2")!) {
        let transport = JSONRPCTransport(url: relayUrl)
        self.crypto = Crypto()
        self.relay = Relay(transport: transport, crypto: crypto)
    }
    
    public func pair(with url: String) throws {
        guard let pairingParamsUri = PairParamsUri(url) else {
            throw WalletConnectError.PairingParamsUriInitialization
        }
        let proposal = formatPairingProposal(from: pairingParamsUri)

        let peerPublic = Data(hex: proposal.proposer.publicKey)
        let privateKey = Crypto.X25519.generatePrivateKey()
        let selfParticipant = PairingParticipant(publicKey: privateKey.publicKey.toHexString())
        let agreementKeys = try Crypto.X25519.generateAgreementKeys(peerPublicKey: peerPublic, privateKey: privateKey)
        crypto.set(agreementKeys: agreementKeys, topic: proposal.topic)
        crypto.set(privateKey: privateKey)
        let expiry = proposal.ttl + Int(Date().timeIntervalSince1970)
        let appMetadata = AppMetadata(name: "iOS", description: nil, url: nil, icons: nil)
        let approve = PairingApproveParams(topic: proposal.topic,
                                           relay: RelayProtocolOptions(protocol: "waku", params: nil),
                                           responder: selfParticipant,
                                           expiry: expiry,
                                           state: PairingState(metadata: appMetadata))
        let jsonRpc = ClientSynchJSONRPC(method: ClientSynchJSONRPC.Method.pairingApprove, params: ClientSynchJSONRPC.Params.pairingApprove(approve))
        relay.publish(topic: proposal.topic, payload: jsonRpc)
    }
    
    func formatPairingProposal(from uri: PairParamsUri) -> PairingProposal {
        return PairingProposal(topic: uri.topic,
                               relay: uri.relay,
                               proposer: PairingProposer(publicKey: uri.publicKey,
                                                         controller: uri.controller),
                               signal: PairingSignal(params: PairingSignal.Params(uri: uri.raw)),
                               permissions: PairingProposedPermissions(jsonrpc: PairingProposedPermissions.JSONRPC(methods: [])),
                               ttl: Pairing.defaultTtl)
    }
}


enum SequenceStatus {
    case pending
    case proposed
    case responded
    case settled
}

protocol Sequence {
    var status: SequenceStatus {get set}
}
