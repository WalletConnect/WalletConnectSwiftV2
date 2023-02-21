import Foundation

public struct JsonRpcID {

    public static func generate() -> Int64 {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000) * 1000
        let random = Int64.random(in: 0..<1000)
        return timestamp + random
    }

    public static func timestamp(from id: Int64) -> Date {
        let interval = TimeInterval(id / 1000 / 1000)
        return Date(timeIntervalSince1970: interval)
    }
}
