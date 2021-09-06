
import Foundation

extension SessionType {
    struct Signal: Codable {
        struct Params: Codable {
            let topic: String
        }
        let method: String
        let params: Params
    }
}


