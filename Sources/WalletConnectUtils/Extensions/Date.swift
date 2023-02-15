
import Foundation

public extension Date {
    var millisecondsSince1970: UInt64 {
        UInt64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds: UInt64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}
