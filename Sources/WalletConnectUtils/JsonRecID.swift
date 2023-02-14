import Foundation

public struct JsonRpcID {

    public static func generate() -> Int64 {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000 * pow(10, 6))
        let random = Int64.random(in: 0..<1000)
        let extra = Int64(ceil(Float(random) * (pow(10, 6))))
        return timestamp + extra
    }

    public static func timestamp(from id: Int64) -> Date {
        let interval = TimeInterval(id / 1000 / 1000000)
        return Date(timeIntervalSince1970: interval)
    }
}
