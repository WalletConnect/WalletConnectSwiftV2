struct AnyError: Error {}

struct EmptyCodable: Codable {}

struct FailableCodable: Codable {
    
    func encode(to encoder: Encoder) throws {
        throw AnyError()
    }
}
