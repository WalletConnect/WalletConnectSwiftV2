// 

import Foundation

public class WalletConnectClient {
    
    public init(relayUrl: URL = URL(string: "wss://relay.walletconnect.org/?protocol=wc&version=2")!) {
    }
    
    public func pair(with url: String) throws {
        guard let pairingParamsUri = PairingType.ParamsUri(url) else {
            throw WalletConnectError.PairingParamsUriInitialization
        }
        let proposal = formatPairingProposal(from: pairingParamsUri)
    }
    let defaultTtl = 2592000
    func formatPairingProposal(from uri: PairingType.ParamsUri) -> PairingType.Proposal {
        return PairingType.Proposal(topic: uri.topic,
                               relay: uri.relay,
                               proposer: PairingType.Proposer(publicKey: uri.publicKey,
                                                         controller: uri.controller),
                               signal: PairingType.Signal(params: PairingType.Signal.Params(uri: uri.raw)),
                               permissions: PairingType.ProposedPermissions(jsonrpc: PairingType.JSONRPC(methods: [])),
                               ttl: defaultTtl)
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
