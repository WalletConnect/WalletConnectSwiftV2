import Foundation

public typealias RPCID = Either<String, Int64>

public protocol IdentifierGenerator {
    func next() -> RPCID
}

struct IntIdentifierGenerator: IdentifierGenerator {

    func next() -> RPCID {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000) * 1000
        let random = Int64.random(in: 0..<1000)
        return RPCID(timestamp + random)
    }
}

extension RPCID {

    public var timestamp: Date {
        guard let id = self.right else { return .distantPast }
        let interval = TimeInterval(id / 1000 / 1000)
        return Date(timeIntervalSince1970: interval)
    }
}
