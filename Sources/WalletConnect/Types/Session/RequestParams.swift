
import Foundation

extension SessionType {
    public struct RequestParams: Codable, Equatable {
        let topic: String
        let method: String
        let params: String
        let timeout: Int?
        let chainId: String?
    }
}
