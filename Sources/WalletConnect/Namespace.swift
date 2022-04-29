public struct Namespace: Codable, Equatable, Hashable {
    public let chains: Set<Blockchain>
    public let methods: Set<String>
    public let events: Set<String>
}
