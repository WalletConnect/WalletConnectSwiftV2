
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
        let params: String // String until we not agree on protocol level
    }
}
//
//extension SessionType.PayloadParams.Request {
//    enum Params: Codable, Equatable {
//        init(from decoder: Decoder) throws {
//            fatalError("not implemented")
//        }
//
//        func encode(to encoder: Encoder) throws {
//            fatalError("not implemented")
//        }
//    }
//}
