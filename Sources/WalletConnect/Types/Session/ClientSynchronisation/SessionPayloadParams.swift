
import Foundation
import WalletConnectUtils

extension SessionType {
    struct PayloadParams: Codable, Equatable {
        let request: Request
        let chainId: String?
    }
}

extension SessionType.PayloadParams {
    struct Request: Codable, Equatable {
        let method: String
        let params: AnyCodable
    }
}
