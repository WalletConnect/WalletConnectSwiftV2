// 

import Foundation

enum JSONRPCSerialiserError: String, Error, CustomStringConvertible {
    case messageToShort = "Error: message is to short"
    var description: String {
        return rawValue
    }
}
