public struct AnyError: Error {}

public struct EmptyCodable: Codable {
    public init() {}
}

public struct FailableCodable: Codable {
    public init() {}
    public func encode(to encoder: Encoder) throws {
        throw AnyError()
    }
}
