
import Foundation

extension SessionType {
    struct PayloadParams: Codable {
        let request: Request
        let chainId: String?
    }
}

extension SessionType.PayloadParams {
    struct Request: Codable {
        let method: String
        let params: Params
    }
}

extension SessionType.PayloadParams.Request {
    enum Params: Codable {
        init(from decoder: Decoder) throws {
            fatalError("not implemented")
        }
        
        func encode(to encoder: Encoder) throws {
            fatalError("not implemented")
        }
    }
}
