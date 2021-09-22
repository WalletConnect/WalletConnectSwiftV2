
import Foundation

public struct DisconnectParams: Codable, Equatable {
    let reason: Reason
    let topic: String
    struct Reason: Codable, Equatable {
        let code: Int
        let message: String
    }
}
