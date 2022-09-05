import Foundation

public protocol ProtocolMethod {
    var method: String { get }
    var requestTag: Int { get }
    var responseTag: Int { get }
}
