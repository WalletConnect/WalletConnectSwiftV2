
import Foundation

extension SessionType {
    public struct PayloadParams: Codable, Equatable {
        let request: Request
        let chainId: String?
    }
}

extension SessionType.PayloadParams {
    public struct Request: Codable, Equatable {
        let method: String
        let params: AnyCodable
    }
}
