import Foundation

public protocol IATProvider {
    var iat: String { get }
}

public struct DefaultIATProvider: IATProvider {

    public init() { }

    public var iat: String {
        return ISO8601DateFormatter().string(from: Date())
    }
}
