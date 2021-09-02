
import Foundation

struct SessionPayloadParams: Codable {
    let request: Request
    let chainId: String?
}

extension SessionPayloadParams {
    struct Request: Codable {
        let method: String
        let params: Params
    }
}

extension SessionPayloadParams.Request {
    enum Params: Codable {
        init(from decoder: Decoder) throws {
            fatalError("not implemented")
        }
        
        func encode(to encoder: Encoder) throws {
            fatalError("not implemented")
        }
    }
}
