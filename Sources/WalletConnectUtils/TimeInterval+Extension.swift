import Foundation

public extension TimeInterval {

    static var day: TimeInterval {
        24 * .hour
    }

    static var hour: TimeInterval {
        60 * .minute
    }

    static var minute: TimeInterval {
        60
    }
}
