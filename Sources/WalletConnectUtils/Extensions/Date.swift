
import Foundation

public extension Date {
    public var millisecondsSince1970: UInt64 {
        UInt64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
}
