import Foundation

protocol Expirable {
    func isExpired(currentDate: Date) -> Bool
}
extension Expirable {
    func isExpired(currentDate: Date = Date()) -> Bool {
        return isExpired(currentDate: currentDate)
    }
}

public struct Request: Codable, Equatable, Expirable {
    public enum Errors: Error {
        case invalidTtl
        case requestExpired
    }

    public let id: RPCID
    public let topic: String
    public let method: String
    public let params: AnyCodable
    public let chainId: Blockchain
    public var expiryTimestamp: UInt64?

    // TTL bounds
    static let minTtl: TimeInterval = 300    // 5 minutes
    static let maxTtl: TimeInterval = 604800 // 7 days

    
    /// - Parameters:
    ///   - topic: topic of a session
    ///   - method: request method
    ///   - params: request params
    ///   - chainId: chain id
    ///   - ttl: ttl of a request, will be used to calculate expiry, 10 minutes by default
    public init(topic: String, method: String, params: AnyCodable, chainId: Blockchain, ttl: TimeInterval = 300) throws {
        guard ttl >= Request.minTtl && ttl <= Request.maxTtl else {
            throw Errors.invalidTtl
        }

        let calculatedExpiry = UInt64(Date().timeIntervalSince1970) + UInt64(ttl)
        self.init(id: RPCID(JsonRpcID.generate()), topic: topic, method: method, params: params, chainId: chainId, expiryTimestamp: calculatedExpiry)
    }

    init<C>(id: RPCID, topic: String, method: String, params: C, chainId: Blockchain, ttl: TimeInterval = 300) throws where C: Codable {
        guard ttl >= Request.minTtl && ttl <= Request.maxTtl else {
            throw Errors.invalidTtl
        }

        let calculatedExpiry = UInt64(Date().timeIntervalSince1970) + UInt64(ttl)
        self.init(id: id, topic: topic, method: method, params: AnyCodable(params), chainId: chainId, expiryTimestamp: calculatedExpiry)
    }

    internal init(id: RPCID, topic: String, method: String, params: AnyCodable, chainId: Blockchain, expiryTimestamp: UInt64?) {
        self.id = id
        self.topic = topic
        self.method = method
        self.params = params
        self.chainId = chainId
        self.expiryTimestamp = expiryTimestamp
    }

    func isExpired(currentDate: Date = Date()) -> Bool {
        guard let expiry = expiryTimestamp else { return false }
        let expiryDate = Date(timeIntervalSince1970: TimeInterval(expiry))
        return expiryDate < currentDate
    }

    func calculateTtl(currentDate: Date = Date()) throws -> Int {
        guard let expiry = expiryTimestamp else { return Int(Self.minTtl) }
        
        let expiryDate = Date(timeIntervalSince1970: TimeInterval(expiry))
        let diff = expiryDate.timeIntervalSince(currentDate)

        guard diff > 0 else {
            throw Errors.requestExpired
        }

        return Int(diff)
    }
}
