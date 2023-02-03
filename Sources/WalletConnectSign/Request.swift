import Foundation

public struct Request: Codable, Equatable {
    public let id: RPCID
    public let topic: String
    public let method: String
    public let params: AnyCodable
    public let chainId: Blockchain
    public let expiry: UInt64?

    internal init(id: RPCID, topic: String, method: String, params: AnyCodable, chainId: Blockchain, expiry: UInt64?) {
        self.id = id
        self.topic = topic
        self.method = method
        self.params = params
        self.chainId = chainId
        self.expiry = expiry
    }

    public init(topic: String, method: String, params: AnyCodable, chainId: Blockchain, expiry: UInt64? = nil) {
        self.init(id: RPCID(JsonRpcID.generate()), topic: topic, method: method, params: params, chainId: chainId, expiry: expiry)
    }

    init<C>(id: RPCID, topic: String, method: String, params: C, chainId: Blockchain, expiry: UInt64?) where C: Codable {
        self.init(id: id, topic: topic, method: method, params: AnyCodable(params), chainId: chainId, expiry: expiry)
    }

    func isExpired(currentDate: Date = Date()) -> Bool {
        guard let expiry = expiry else { return false }

        let expiryDate = Date(timeIntervalSince1970: TimeInterval(expiry))

        guard
            abs(currentDate.distance(to: expiryDate)) < Constants.maxExpiry,
            abs(currentDate.distance(to: expiryDate)) > Constants.minExpiry
        else { return true  }

        return expiryDate < currentDate
    }

    func calculateTtl(currentDate: Date = Date()) -> Int {
        guard let expiry = expiry else { return SessionRequestProtocolMethod.defaultTtl }

        let expiryDate = Date(timeIntervalSince1970: TimeInterval(expiry))
        let diff = expiryDate - currentDate.timeIntervalSince1970

        guard
            diff.timeIntervalSince1970 < Constants.maxExpiry,
            diff.timeIntervalSince1970 > Constants.minExpiry
        else { return SessionRequestProtocolMethod.defaultTtl }

        return Int(diff.timeIntervalSince1970)
    }
}

private extension Request {

    struct Constants {
        static let minExpiry: TimeInterval = 300    // 5 minutes
        static let maxExpiry: TimeInterval = 604800 // 7 days
    }
}
