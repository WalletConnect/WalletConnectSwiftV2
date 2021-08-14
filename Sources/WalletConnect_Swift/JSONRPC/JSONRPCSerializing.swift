// 

import Foundation

protocol JSONRPCSerialising {
    var codec: Codec {get}
    func serialise(json: String) -> String
    func deserialise(message: String) -> String
}

class JSONRPCSerialiser: JSONRPCSerialising {
    var codec: Codec
    
    init(codec: Codec) {
        self.codec = codec
    }
    
    func deserialise(message: String) -> String {
        return ""
    }
    
    func serialise(json: String) -> String {
        return ""
    }
}
