import JSONRPC

public final class RPCHistory {

    public struct Record: Codable {
        public enum Origin: String, Codable {
            case local
            case remote
        }
        let id: RPCID
        let topic: String
        let origin: Origin
        public let request: RPCRequest
        var response: RPCResponse?
    }

    enum HistoryError: Error {
        case unidentifiedRequest
        case unidentifiedResponse
        case requestDuplicateNotAllowed
        case responseDuplicateNotAllowed
        case requestMatchingResponseNotFound
    }

    private let storage: CodableStore<Record>

    public init(keyValueStore: CodableStore<Record>) {
        self.storage = keyValueStore
    }

    public func get(recordId: RPCID) -> Record? {
        try? storage.get(key: "\(recordId)")
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

    public func resolve(_ response: RPCResponse) throws {
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
    }

    public func deleteAll(forTopic topic: String) {
        storage.getAll().forEach { record in
            if record.topic == topic {
                storage.delete(forKey: "\(record.id)")
            }
        }
    }
}
