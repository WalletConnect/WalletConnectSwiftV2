public final class RPCHistory {

    public struct Record: Codable {
        public enum Origin: String, Codable {
            case local
            case remote
        }
        public let id: RPCID
        public let topic: String
        let origin: Origin
        public let request: RPCRequest
        public var response: RPCResponse?
    }

    enum HistoryError: Error {
        case unidentifiedRequest
        case unidentifiedResponse
        case requestDuplicateNotAllowed
        case responseDuplicateNotAllowed
        case requestMatchingResponseNotFound
    }

    private let storage: CodableStore<Record>

    init(keyValueStore: CodableStore<Record>) {
        self.storage = keyValueStore
    }

    public func get(recordId: RPCID) -> Record? {
        try? storage.get(key: recordId.string)
    }

    public func set(_ request: RPCRequest, forTopic topic: String, emmitedBy origin: Record.Origin) throws {
        guard let id = request.id else {
            throw HistoryError.unidentifiedRequest
        }
        guard get(recordId: id) == nil else {
            throw HistoryError.requestDuplicateNotAllowed
        }
        let record = Record(id: id, topic: topic, origin: origin, request: request)
        storage.set(record, forKey: "\(record.id)")
    }

    @discardableResult
    public func resolve(_ response: RPCResponse) throws -> Record {
        guard let id = response.id else {
            throw HistoryError.unidentifiedResponse
        }
        guard var record = get(recordId: id) else {
            throw HistoryError.requestMatchingResponseNotFound
        }
        guard record.response == nil else {
            throw HistoryError.responseDuplicateNotAllowed
        }
        record.response = response
        storage.set(record, forKey: "\(record.id)")
        return record
    }

    public func deleteAll(forTopics topics: [String]){
        storage.getAll().forEach { record in
            if topics.contains(record.topic) {
                storage.delete(forKey: "\(record.id)")
            }
        }
    }

    public func getAll<Object: Codable>(of type: Object.Type, topic: String) -> [Object] {
        return storage.getAll()
            .filter{$0.topic == topic}
            .compactMap { try? $0.request.params?.get(Object.self) }
    }

    public func getAll<Object: Codable>(of type: Object.Type) -> [Object] {
        return getAllWithIDs(of: type).map { $0.value }
    }

    public func getAllWithIDs<Object: Codable>(of type: Object.Type) -> [(id: RPCID, value: Object)] {
        return storage.getAll().compactMap { record in
            guard let object = try? record.request.params?.get(Object.self)
            else { return nil }
            return (record.id, object)
        }
    }

    public func delete(id: RPCID) {
        storage.delete(forKey: id.string)
    }

    public func deleteAll(forTopic topic: String) {
        deleteAll(forTopics: [topic])
    }

    public func getPending() -> [Record] {
        storage.getAll().filter { $0.response == nil }
    }
}
