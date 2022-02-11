
import Foundation
import KMS

public protocol JSONRPCSerializing {
    func serialize(topic: String, encodable: Encodable) throws -> String
    func tryDeserialize<T: Codable>(topic: String, message: String) -> T?
}

extension JSONRPCSerializer: JSONRPCSerializing {}
