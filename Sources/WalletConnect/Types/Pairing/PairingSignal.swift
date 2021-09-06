
import Foundation

extension PairingType {
    struct Signal: Codable {
        struct Params: Codable {
            let uri: String
        }
        let type = "uri"
        let params: Params
    }
}
