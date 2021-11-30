
import Foundation

extension PairingType {
    
    struct Signal: Codable, Equatable {
        let type: String
        let params: Params
        
        init(uri: String) {
            self.type = "uri"
            self.params = Params(uri: uri)
        }
        
        struct Params: Codable, Equatable {
            let uri: String
        }
    }
}
