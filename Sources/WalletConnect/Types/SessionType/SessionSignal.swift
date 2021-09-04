
import Foundation

extension SessionType {
    struct Signal: Codable, Equatable {
        struct Params: Codable, Equatable {
            let topic: String
        }
        let method: String
        let params: Params
    }
}


