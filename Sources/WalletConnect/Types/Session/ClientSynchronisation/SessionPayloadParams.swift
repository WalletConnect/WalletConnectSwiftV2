
import Foundation

extension SessionType {
    struct PayloadParams: Codable, Equatable {
        let request: Request
        let chainId: String?
    }
}

extension SessionType.PayloadParams {
    struct Request: Codable, Equatable {
        let method: String
        let params: Params
    }
}

extension SessionType.PayloadParams.Request {
    enum Params: Codable, Equatable {
        init(from decoder: Decoder) throws {
            fatalError("not implemented")
        }
        
        func encode(to encoder: Encoder) throws {
            fatalError("not implemented")
        }
    }
}
