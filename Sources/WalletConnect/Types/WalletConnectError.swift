// 

import Foundation

enum WalletConnectError: Error, CustomStringConvertible {
    // 1000 (Internal)
    case sessionNotApproved
    case PairingParamsUriInitialization
    case unauthorizedMatchingController
    case pairingProposalGenerationFailed
    // 2000 (Timeout)
    // 3000 (Unauthorized)
    // 4000 (EIP-1193)
    // 5000 (CAIP-25)
    // 9000 (Unknown)
    
    //FIX add codes matching js repo
    var code: Int {
        switch self {
        case .PairingParamsUriInitialization:
            fatalError("Not implemented")
        case .unauthorizedMatchingController:
            fatalError("Not implemented")
        case .pairingProposalGenerationFailed:
            fatalError("Not implemented")
        case .sessionNotApproved:
            return 1601
        }
    }
    
    //FIX descriptions
    var message: String {
        switch self {
        case .PairingParamsUriInitialization:
            return "PairingParamsUriInitialization"
        case .unauthorizedMatchingController:
            return "unauthorizedMatchingController"
        case .pairingProposalGenerationFailed:
            return "pairingProposalGenerationFailed"
        case .sessionNotApproved:
            return "Session not approved"
        }
    }
}
