public struct Blockchain: Equatable {
    
    public let namespace: String
    
    public let reference: String
    
    public var absoluteString: String {
        "\(namespace):\(reference)"
    }
    
    public init?(_ string: String) {
        guard String.conformsToCAIP2(string) else { return nil }
        let splits = string.split(separator: ":")
        self.namespace = String(splits[0])
        self.reference = String(splits[1])
    }
    
    public init?(namespace: String, reference: String) {
        self.init("\(namespace):\(reference)")
    }
}

extension Blockchain: LosslessStringConvertible {
    public var description: String {
        return absoluteString
    }
}

extension Blockchain: Codable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let absoluteString = try container.decode(String.self)
        guard let blockchain = Blockchain(absoluteString) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Malformed CAIP-2 chain identifier.")
        }
        self = blockchain
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(absoluteString)
    }
}
