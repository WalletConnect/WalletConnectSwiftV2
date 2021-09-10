// 

import Foundation

public class WalletConnectClient {
    
    let metadata: AppMetadata
    
    let isController: Bool
    
    private var pairingEngine: SequenceEngine
    
    public init(options: WalletClientOptions) {
        self.isController = options.isController
        self.metadata = options.metadata
        self.pairingEngine = PairingEngine()
        // TODO: Store api key and setup relayer
    }
    
    public func pair(uriString: String, completion: @escaping (Result<String, Error>) -> Void) throws {
        guard let pairingURI = PairingType.ParamsUri(uriString) else {
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
}
