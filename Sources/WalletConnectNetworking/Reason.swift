import Foundation

public protocol Reason {
    var code: Int { get }
    var message: String { get }
}
