import Foundation

public protocol TimeProvider {
    var currentDate: Date { get }
}

public struct DefaultTimeProvider: TimeProvider {
    public init() {}
    public var currentDate: Date {
        return Date()
    }
}
