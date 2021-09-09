// 

import Foundation

public class WalletConnectClient {
    
    let metadata: AppMetadata
    
    let isController: Bool
    
    private var pairingEngine: SequenceEngine!
    
    public init(options: WalletClientOptions) {
        self.isController = options.isController
        self.metadata = options.metadata
//        self.pairingEngine
        // store api key
        // setup relayer
    }
    
    public func pair(with url: String, completion: @escaping (Result<String, Error>) -> Void) throws {
        guard let pairingParamsUri = PairingType.ParamsUri(url) else {
            throw WalletConnectError.PairingParamsUriInitialization
        }
        let proposal = formatPairingProposal(from: pairingParamsUri)
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
