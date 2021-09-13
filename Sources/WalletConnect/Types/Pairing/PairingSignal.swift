
import Foundation

extension PairingType {
    struct Signal: Codable, Equatable {
        struct Params: Codable, Equatable {
            let uri: String
        }
        let type = "uri"
        let params: Params
    }
}
