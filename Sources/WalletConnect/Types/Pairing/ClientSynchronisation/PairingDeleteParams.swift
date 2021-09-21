
import Foundation

extension PairingType {
    struct DeleteParams: Codable, Equatable {
        let reason: Reason
        struct Reason: Codable, Equatable {
            let code: Int
            let message: String
        }
    }
}
