import Commons

/**
 TODO: Add documentation
 */
public struct RPCResponse: Equatable {
    
    public let jsonrpc: String
    
    public let id: ID?
    
    public var result: AnyCodable? {
        if case .success(let value) = internalResult { return value }
        return nil
    }
    
    public var error: JSONRPCError? {
        if case .failure(let error) = internalResult { return error }
        return nil
    }
    
    private let internalResult: Result<AnyCodable, JSONRPCError>
    
    internal init(id: ID?, outcome: Result<AnyCodable, JSONRPCError>) {
        self.jsonrpc = "2.0"
        self.id = id
        self.internalResult = outcome
    }
    
    public init<C>(id: Int, result: C) where C: Codable {
        self.init(id: ID(id), outcome: .success(AnyCodable(result)))
    }
    
    public init<C>(id: String, result: C) where C: Codable {
        self.init(id: ID(id), outcome: .success(AnyCodable(result)))
    }
}

extension RPCResponse: Codable {
    
    enum CodingKeys: CodingKey {
        case jsonrpc
        case result
        case error
        case id
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
        guard jsonrpc == "2.0" else {
            throw DecodingError.dataCorruptedError(forKey: .jsonrpc, in: container, debugDescription: "err1")
        }
        id = try? container.decode(ID.self, forKey: .id)
        let result = try? container.decode(AnyCodable.self, forKey: .result)
        let error = try? container.decode(JSONRPCError.self, forKey: .error)
        if let result = result {
            guard id != nil else {
                throw DecodingError.dataCorrupted(.init(codingPath: [CodingKeys.result, CodingKeys.id], debugDescription: "err res", underlyingError: nil))
            }
            guard error == nil else {
                throw DecodingError.dataCorrupted(.init(codingPath: [CodingKeys.result, CodingKeys.error], debugDescription: "err2", underlyingError: nil))
            }
            internalResult = .success(result)
        } else if let error = error {
            internalResult = .failure(error)
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: [CodingKeys.result, CodingKeys.error], debugDescription: "err3", underlyingError: nil))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encode(id, forKey: .id)
        switch internalResult {
        case .success(let anyCodable):
            try container.encode(anyCodable, forKey: .result)
        case .failure(let rpcError):
            try container.encode(rpcError, forKey: .error)
        }
    }
}
