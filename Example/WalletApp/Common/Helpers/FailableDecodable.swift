@propertyWrapper
struct FailableDecodable<Wrapped: Codable & Hashable>: Codable, Hashable {
    var wrappedValue: Wrapped?

    init(_ wrappedValue: Wrapped?) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = try? container.decode(Wrapped.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}
