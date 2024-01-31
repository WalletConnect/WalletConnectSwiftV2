import Foundation

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
        public let response: RPCResponse?
        public var timestamp: Date?
    }

    enum HistoryError: Error, LocalizedError {
        case unidentifiedRequest
        case unidentifiedResponse
        case requestDuplicateNotAllowed
        case responseDuplicateNotAllowed
        case requestMatchingResponseNotFound
        var errorDescription: String? {
            switch self {
            case .unidentifiedRequest:
                return "Unidentified request."
            case .unidentifiedResponse:
                return "Unidentified response."
            case .requestDuplicateNotAllowed:
                return "Request duplicates are not allowed."
            case .responseDuplicateNotAllowed:
                return "Response duplicates are not allowed."
            case .requestMatchingResponseNotFound:
                return "Matching request for the response not found."
            }
        }
    }


    private let storage: CodableStore<Record>

    init(keyValueStore: CodableStore<Record>) {
        self.storage = keyValueStore

        removeOutdated()
    }

    public func get(recordId: RPCID) -> Record? {
        try? storage.get(key: recordId.string)
    }

    public func set(_ request: RPCRequest, forTopic topic: String, emmitedBy origin: Record.Origin, time: TimeProvider = DefaultTimeProvider()) throws {
        guard let id = request.id else {
            throw HistoryError.unidentifiedRequest
        }
        guard get(recordId: id) == nil else {
            throw HistoryError.requestDuplicateNotAllowed
        }
        let record = Record(id: id, topic: topic, origin: origin, request: request, response: nil, timestamp: time.currentDate)
        storage.set(record, forKey: "\(record.id)")
    }

    @discardableResult
    public func resolve(_ response: RPCResponse) throws -> Record {
        let record = try validate(response)
        storage.delete(forKey: "\(record.id)")
        return record
    }

    @discardableResult
    public func validate(_ response: RPCResponse) throws -> Record {
        guard let id = response.id else {
            throw HistoryError.unidentifiedResponse
        }
        guard let record = get(recordId: id) else {
            throw HistoryError.requestMatchingResponseNotFound
        }
        guard record.response == nil else {
            throw HistoryError.responseDuplicateNotAllowed
        }
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

    public func deleteAll() {
        storage.deleteAll()
    }
}

extension RPCHistory {

    func removeOutdated() {
        let records = storage.getAll()

        let thirtyDays: TimeInterval = 30*86400

        for var record in records {
            if let timestamp = record.timestamp {
                if timestamp.distance(to: Date()) > thirtyDays {
                    storage.delete(forKey: record.id.string)
                }
            } else {
                record.timestamp = Date()
                storage.set(record, forKey: "\(record.id)")
            }
        }
    }
}
